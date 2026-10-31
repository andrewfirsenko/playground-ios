//
//  AnyCache.swift
//  TypedCache
//
//  Created by Andrew on 31.10.2026.
//


struct AnyCache<Key: Hashable, Value>: Cache {
    private var cache: any Cache<Key, Value>
    
    init(_ cache: any Cache<Key, Value>) {
        guard let anyCache = cache as? AnyCache else {
            self.cache = cache
            return
        }
        self.cache = anyCache.cache
    }
    
    var count: Int {
        return cache.count
    }
    
    mutating func value(forKey key: Key) -> Value? {
        return cache.value(forKey: key)
    }
    
    mutating func setValue(_ value: Value, forKey key: Key) {
        cache.setValue(value, forKey: key)
    }
    
    @discardableResult
    mutating func removeValue(forKey key: Key) -> Value? {
        return cache.removeValue(forKey: key)
    }
}
