#if PART2
import Testing
@testable import TypedCache

@Suite("Часть 2. AnyCache")
struct Part2AnyCacheTests {

    @Test func wrapsConcreteCache() {
        var erased = AnyCache(LRUCache<String, Int>(capacity: 1))
        erased["a"] = 1
        erased["b"] = 2

        #expect(erased.count == 1)
        #expect(erased["a"] == nil)
        #expect(erased["b"] == 2)
    }

    @Test func wrapsExistentialFromContainer() {
        let fromContainer: any Cache<String, Int> = LRUCache<String, Int>(capacity: 2)
        var erased = AnyCache(fromContainer)
        erased["a"] = 1

        #expect(erased.count == 1)
    }

    @Test func storesDifferentCachesInOneArray() {
        var caches: [AnyCache<String, Int>] = [
            AnyCache(LRUCache(capacity: 1)),
            AnyCache(UnboundedCache()),
        ]
        for index in caches.indices {
            caches[index]["a"] = 1
            caches[index]["b"] = 2
        }

        #expect(caches.map(\.count) == [1, 2])
    }

    @Test func conformsToCacheItself() {
        func fill<C: Cache<String, Int>>(_ cache: inout C) {
            cache["x"] = 1
        }

        var erased = AnyCache(UnboundedCache<String, Int>())
        fill(&erased)

        #expect(erased["x"] == 1)
    }

    @Test func keepsValueSemantics() {
        let original = AnyCache(UnboundedCache<String, Int>())
        var copy = original
        copy["x"] = 1

        #expect(original.isEmpty)
        #expect(copy.count == 1)
    }
}
#endif
