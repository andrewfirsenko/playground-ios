#if BONUS
import Synchronization
import Testing
@testable import TypedCache

final class SlowLoader: DataLoader, Sendable {
    private let calls = Mutex(0)
    private let shouldFail: Bool

    init(shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    var callCount: Int {
        calls.withLock { $0 }
    }

    func load(_ key: String) async throws(LoadError) -> Int {
        calls.withLock { $0 += 1 }
        try? await Task.sleep(for: .milliseconds(100))
        if shouldFail {
            throw .notFound(key)
        }
        return key.count
    }
}

private typealias SlowCache = ReadThroughCache<LRUCache<String, Int>, SlowLoader>

private func failure(of cache: SlowCache, key: String) async -> LoadError? {
    do throws(LoadError) {
        _ = try await cache.value(forKey: key)
        return nil
    } catch {
        return error
    }
}

@Suite("Бонус. Склейка одновременных запросов")
struct BonusCoalescingTests {

    @Test func concurrentRequestsForSameKeyLoadOnce() async throws {
        let loader = SlowLoader(shouldFail: false)
        let cache = SlowCache(cache: LRUCache(capacity: 10), loader: loader)

        async let first = cache.value(forKey: "key")
        async let second = cache.value(forKey: "key")
        async let third = cache.value(forKey: "key")
        let values = try await [first, second, third]

        #expect(values == [3, 3, 3])
        #expect(loader.callCount == 1)
    }

    @Test func sharedFailureReachesEveryoneAndIsRetriedLater() async {
        let loader = SlowLoader(shouldFail: true)
        let cache = SlowCache(cache: LRUCache(capacity: 10), loader: loader)

        async let first = failure(of: cache, key: "key")
        async let second = failure(of: cache, key: "key")
        let errors = await [first, second]

        #expect(errors == [.notFound("key"), .notFound("key")])
        #expect(loader.callCount == 1)

        _ = await failure(of: cache, key: "key")
        #expect(loader.callCount == 2)
    }
}
#endif
