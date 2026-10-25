import Foundation
import Testing
@testable import AdapterFacade

// MARK: - Test doubles

private final class MockCancellable: Cancellable, @unchecked Sendable {
    private let counter = ThreadSafeWrapper(0)

    var cancelCount: Int { counter.value }

    func cancel() {
        counter.mutate { $0 += 1 }
    }
}

private final class MockLegacyGeoService: LegacyGeoServiceLogic, @unchecked Sendable {
    typealias Completion = ([String: Any]?, Error?) -> Void

    struct Response {
        var data: [String: Any]?
        var error: Error?
    }

    private struct State {
        var fetchCount = 0
        var completion: Completion?
    }

    let cancellable = MockCancellable()
    private let state = ThreadSafeWrapper(State())
    /// Ответы, которые сервис отдаёт синхронно внутри fetch (до возврата токена).
    private let syncResponses: [Response]

    init(syncResponses: [Response] = []) {
        self.syncResponses = syncResponses
    }

    var fetchCount: Int { state.value.fetchCount }

    func fetch(code: String, completion: @escaping Completion) -> Cancellable {
        state.mutate {
            $0.fetchCount += 1
            $0.completion = completion
        }
        for response in syncResponses {
            completion(response.data, response.error)
        }
        return cancellable
    }

    /// Вызвать completion вручную, в любой момент и с любого потока.
    func complete(data: [String: Any]?, error: Error? = nil) {
        state.value.completion?(data, error)
    }

    func waitUntilFetched() async {
        while fetchCount == 0 {
            await Task.yield()
        }
    }
}

private enum Fixture {
    static var paris: [String: Any] { ["code": "FR", "name": "France", "capital": "Paris"] }
    static var berlin: [String: Any] { ["code": "DE", "name": "Germany", "capital": "Berlin"] }

    static let france = Country(code: "FR", name: "France", capital: "Paris")
    static let germany = Country(code: "DE", name: "Germany", capital: "Berlin")
}

private struct StubError: Error {}

private extension Result where Failure == GeoError {
    var country: Success? {
        if case let .success(value) = self { value } else { nil }
    }

    var isCancelled: Bool {
        if case .failure(.cancelled) = self { true } else { false }
    }
}

private func run(_ adapter: LegacyGeoServiceAdapter, code: String = "FR") async -> Result<Country, GeoError> {
    do throws(GeoError) {
        return .success(try await adapter.country(code: code))
    } catch {
        return .failure(error)
    }
}

// MARK: - Tests

@Suite("LegacyGeoServiceAdapter", .timeLimit(.minutes(1)))
struct LegacyGeoServiceAdapterTests {
    // MARK: Double completion

    @Test("completion вызван дважды синхронно: краша нет, вернулось первое значение")
    func completionCalledTwiceSynchronously() async {
        let service = MockLegacyGeoService(syncResponses: [
            .init(data: Fixture.paris),
            .init(data: Fixture.berlin)
        ])
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let result = await run(adapter)

        #expect(result.country == Fixture.france)
    }

    @Test("completion вызван дважды последовательно из другого потока: вернулось первое значение")
    func completionCalledTwiceFromBackground() async {
        let service = MockLegacyGeoService()
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let task = Task { await run(adapter) }
        await service.waitUntilFetched()
        DispatchQueue.global().async {
            service.complete(data: Fixture.paris)
            service.complete(data: Fixture.berlin)
        }

        #expect(await task.value.country == Fixture.france)
    }

    @Test("первый completion с ошибкой, второй с данными: вернулась первая ошибка")
    func errorThenData() async {
        let service = MockLegacyGeoService(syncResponses: [
            .init(error: StubError()),
            .init(data: Fixture.paris)
        ])
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let result = await run(adapter)

        guard case .failure(.network) = result else {
            Issue.record("Ожидалась GeoError.network, получили \(result)")
            return
        }
    }

    // MARK: Cancellation

    @Test("таск отменён: GeoError.cancelled и cancel() у Cancellable")
    func cancellation() async {
        let service = MockLegacyGeoService()
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let task = Task { await run(adapter) }
        await service.waitUntilFetched()
        task.cancel()

        #expect(await task.value.isCancelled)
        #expect(service.cancellable.cancelCount == 1)
    }

    @Test("таск отменён до вызова: GeoError.cancelled, запрос не отправлялся")
    func cancelledBeforeStart() async {
        let service = MockLegacyGeoService()
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let task = Task {
            while !Task.isCancelled { await Task.yield() }
            return await run(adapter)
        }
        task.cancel()

        #expect(await task.value.isCancelled)
        #expect(service.fetchCount == 0)
    }

    @Test("completion после отмены игнорируется, resume не вызывается повторно")
    func completionAfterCancellation() async {
        let service = MockLegacyGeoService()
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let task = Task { await run(adapter) }
        await service.waitUntilFetched()
        task.cancel()
        let result = await task.value

        service.complete(data: Fixture.paris)
        service.complete(data: Fixture.berlin)

        #expect(result.isCancelled)
    }

    // MARK: Races

    @Test("гонка: два completion и cancel одновременно, 1000 итераций", arguments: [1000])
    func raceBetweenCompletionsAndCancel(iterations: Int) async {
        var succeeded = 0
        var cancelled = 0

        for _ in 0..<iterations {
            let service = MockLegacyGeoService()
            let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

            let task = Task { await run(adapter) }
            await service.waitUntilFetched()

            await withTaskGroup(of: Void.self) { group in
                group.addTask { service.complete(data: Fixture.paris) }
                group.addTask { service.complete(data: Fixture.berlin) }
                group.addTask { task.cancel() }
            }

            let result = await task.value
            #expect(service.cancellable.cancelCount <= 1)

            if let country = result.country {
                succeeded += 1
                #expect(country == Fixture.france || country == Fixture.germany)
            } else if result.isCancelled {
                cancelled += 1
                #expect(service.cancellable.cancelCount == 1)
            } else {
                Issue.record("Неожиданный результат: \(result)")
            }
        }

        #expect(succeeded + cancelled == iterations)
    }

    @Test("гонка: отмена во время fetch, пока токен ещё не вернулся", arguments: [1000])
    func raceCancelDuringFetch(iterations: Int) async {
        for _ in 0..<iterations {
            let service = MockLegacyGeoService()
            let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

            let task = Task { await run(adapter) }
            task.cancel()

            let result = await task.value
            service.complete(data: Fixture.paris)

            #expect(result.isCancelled || result.country == Fixture.france)
            #expect(service.cancellable.cancelCount <= 1)
            if service.fetchCount > 0, result.isCancelled {
                #expect(service.cancellable.cancelCount == 1)
            }
        }
    }

    // MARK: Error mapping

    @Test("nil без ошибки: GeoError.notFound")
    func nilDataIsNotFound() async {
        let service = MockLegacyGeoService(syncResponses: [.init(data: nil)])
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let result = await run(adapter)

        guard case .failure(.notFound) = result else {
            Issue.record("Ожидалась GeoError.notFound, получили \(result)")
            return
        }
    }

    @Test("невалидный словарь: GeoError.invalidData")
    func invalidDictionary() async {
        let service = MockLegacyGeoService(syncResponses: [.init(data: ["code": "FR"])])
        let adapter = LegacyGeoServiceAdapter(legacyGeoService: service)

        let result = await run(adapter)

        guard case .failure(.invalidData) = result else {
            Issue.record("Ожидалась GeoError.invalidData, получили \(result)")
            return
        }
    }
}
