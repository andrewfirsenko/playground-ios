//
//  Cache.swift
//  TypedCache
//
//  Created by Andrew on 30.10.2026.
//


protocol Cache<Key, Value> {
    associatedtype Key: Hashable
    associatedtype Value
    
    var count: Int { get }
    mutating func value(forKey key: Key) -> Value?
    mutating func setValue(_ value: Value, forKey key: Key)
    @discardableResult mutating func removeValue(forKey key: Key) -> Value?
}

// MARK: - Helpers
extension Cache {
    var isEmpty: Bool {
        return count == 0
    }
    
    subscript(key: Key) -> Value? {
        mutating get {
            return value(forKey: key)
        }
        set {
            if let newValue {
                setValue(newValue, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }
    
    mutating func value<E: Error>(
        forKey key: Key,
        orInsert: () throws(E) -> Value
    ) throws(E) -> Value {
        if let value = value(forKey: key) {
            return value
        }
        let orValue = try orInsert()
        setValue(orValue, forKey: key)
        return orValue
    }
}
