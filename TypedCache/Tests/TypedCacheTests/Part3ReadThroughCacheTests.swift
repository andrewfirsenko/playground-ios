#if PART3
import Synchronization
import Testing
@testable import TypedCache

enum LoadError: Error, Equatable {
    case notFound(String)
}

/// Значение — длина ключа. Ключи из `missing` бросают `LoadError.notFound`.
final class CountingLoader: DataLoader, Sendable {
    private let requested = Mutex<[String]>([])
    private let missing: Set<String>

    init(missing: Set<String> = []) {
        self.missing = missing
    }

    var requestedKeys: [String] {
        requested.withLock { $0 }
    }

    func load(_ key: String) async throws(LoadError) -> Int {
        requested.withLock { $0.append(key) }
        if missing.contains(key) {
            throw .notFound(key)
        }
        return key.count
    }
}

/// Не бросает вообще. Протокол не должен заставлять его что-то объявлять дополнительно.
struct InfallibleLoader: DataLoader {
    func load(_ key: Int) async -> String {
        String(key)
    }
}

@Suite("Часть 3. ReadThroughCache")
struct Part3ReadThroughCacheTests {

    @Test func loadsOnMissAndServesHitFromCache() async throws {
        let loader = CountingLoader()
        let cache = ReadThroughCache(cache: LRUCache<String, Int>(capacity: 10), loader: loader)

        #expect(try await cache.value(forKey: "swift") == 5)
        #expect(try await cache.value(forKey: "swift") == 5)
        #expect(loader.requestedKeys == ["swift"])
    }

    @Test func respectsEvictionOfUnderlyingCache() async throws {
        let loader = CountingLoader()
        let cache = ReadThroughCache(cache: LRUCache<String, Int>(capacity: 1), loader: loader)

        _ = try await cache.value(forKey: "a")
        _ = try await cache.value(forKey: "bb")
        _ = try await cache.value(forKey: "a")

        #expect(loader.requestedKeys == ["a", "bb", "a"])
    }

    @Test func propagatesTypedErrorAndDoesNotCacheIt() async {
        let loader = CountingLoader(missing: ["ghost"])
        let cache = ReadThroughCache(cache: LRUCache<String, Int>(capacity: 10), loader: loader)

        for _ in 0..<2 {
            do throws(LoadError) {
                _ = try await cache.value(forKey: "ghost")
                Issue.record("Ожидали ошибку")
            } catch {
                #expect(error == .notFound("ghost"))
            }
        }
        #expect(loader.requestedKeys == ["ghost", "ghost"])
    }

    @Test func infallibleLoaderNeedsNoTry() async {
        let cache = ReadThroughCache(cache: UnboundedCache<Int, String>(), loader: InfallibleLoader())

        let value = await cache.value(forKey: 42)

        #expect(value == "42")
    }

    @Test func invalidateForcesReload() async throws {
        let loader = CountingLoader()
        let cache = ReadThroughCache(cache: LRUCache<String, Int>(capacity: 10), loader: loader)

        _ = try await cache.value(forKey: "a")
        await cache.invalidate("a")
        _ = try await cache.value(forKey: "a")

        #expect(loader.requestedKeys == ["a", "a"])
    }

    #if PART2
    @Test func acceptsExistentialCacheFromContainer() async throws {
        let fromContainer: any Cache<String, Int> = LRUCache<String, Int>(capacity: 10)
        let cache = ReadThroughCache(cache: AnyCache(fromContainer), loader: CountingLoader())

        #expect(try await cache.value(forKey: "abc") == 3)
    }
    #endif
}
#endif
