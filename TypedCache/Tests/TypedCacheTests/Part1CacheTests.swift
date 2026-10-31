#if PART1
import Testing
@testable import TypedCache

private func makeCache() -> some Cache<String, Int> {
    LRUCache(capacity: 2)
}

@Suite("Часть 1. Cache и LRUCache")
struct Part1CacheTests {

    // MARK: - Протокол и extension

    @Test func opaqueTypeWithPrimaryAssociatedTypes() {
        var cache = makeCache()
        cache.setValue(1, forKey: "a")
        #expect(cache.value(forKey: "a") == 1)
        #expect(cache.count == 1)
    }

    @Test func subscriptReadsWritesAndRemoves() {
        var cache = UnboundedCache<String, Int>()
        #expect(cache.isEmpty)

        cache["a"] = 1
        #expect(cache["a"] == 1)

        cache["a"] = nil
        #expect(cache["a"] == nil)
        #expect(cache.isEmpty)
    }

    @Test func orInsertCallsFactoryOnlyOnMiss() {
        var cache = UnboundedCache<String, Int>()
        var calls = 0

        // Без `try`: замыкание не бросает.
        let first = cache.value(forKey: "a", orInsert: { calls += 1; return 42 })
        let second = cache.value(forKey: "a", orInsert: { calls += 1; return 0 })

        #expect(first == 42)
        #expect(second == 42)
        #expect(calls == 1)
    }

    @Test func orInsertPropagatesTypedErrorAndDoesNotInsert() {
        var cache = UnboundedCache<String, Int>()

        do throws(TestError) {
            _ = try cache.value(forKey: "a", orInsert: { () throws(TestError) -> Int in throw .boom })
            Issue.record("Ожидали ошибку")
        } catch {
            #expect(error == .boom)
        }
        #expect(cache.isEmpty)
    }

    // MARK: - LRUCache

    @Test func evictsLeastRecentlyUsed() {
        var cache = LRUCache<String, Int>(capacity: 2)
        cache["a"] = 1
        cache["b"] = 2
        _ = cache["a"]  // a теперь самый свежий
        cache["c"] = 3  // вытесняет b

        #expect(cache.count == 2)
        #expect(cache["b"] == nil)
        #expect(cache["a"] == 1)
        #expect(cache["c"] == 3)
    }

    @Test func updatingExistingKeyDoesNotEvict() {
        var cache = LRUCache<String, Int>(capacity: 2)
        cache["a"] = 1
        cache["b"] = 2
        cache["a"] = 10

        #expect(cache.count == 2)
        #expect(cache["a"] == 10)
        #expect(cache["b"] == 2)
    }

    @Test func removeReturnsRemovedValue() {
        var cache = LRUCache<String, Int>(capacity: 2)
        cache["a"] = 1

        #expect(cache.removeValue(forKey: "a") == 1)
        #expect(cache.removeValue(forKey: "a") == nil)
        #expect(cache.isEmpty)
    }

    @Test func iteratesFromMostToLeastRecentWithoutTouchingOrder() {
        var cache = LRUCache<String, Int>(capacity: 3)
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        _ = cache["a"]

        #expect(cache.map(\.key) == ["a", "c", "b"])
        #expect(cache.map(\.key) == ["a", "c", "b"])
        #expect(cache.map(\.value) == [1, 3, 2])
    }

    @Test func hasValueSemantics() {
        var original = LRUCache<String, Int>(capacity: 2)
        original["a"] = 1

        var copy = original
        copy["b"] = 2
        copy["c"] = 3  // в копии вытесняется a

        #expect(original.map(\.key) == ["a"])
        #expect(original["a"] == 1)
        #expect(copy.map(\.key) == ["c", "b"])
    }

    @Test func isSendableWhenKeyAndValueAre() {
        requireSendable(LRUCache<String, Int>.self)
    }
}
#endif
