#if PART1
@testable import TypedCache

/// Реализация на стороне тестов. Если она не компилируется — значит, протокол `Cache`
/// требует больше, чем 4 базовых члена, или их сигнатуры отличаются от README.
struct UnboundedCache<Key: Hashable, Value>: Cache {
    private var storage: [Key: Value] = [:]

    var count: Int { storage.count }

    mutating func value(forKey key: Key) -> Value? {
        storage[key]
    }

    mutating func setValue(_ value: Value, forKey key: Key) {
        storage[key] = value
    }

    @discardableResult
    mutating func removeValue(forKey key: Key) -> Value? {
        storage.removeValue(forKey: key)
    }
}

enum TestError: Error, Equatable {
    case boom
}

func requireSendable<T: Sendable>(_: T.Type) {}
#endif
