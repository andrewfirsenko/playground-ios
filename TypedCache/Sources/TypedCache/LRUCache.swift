//
//  LRUCache.swift
//  TypedCache
//
//  Created by Andrew on 30.10.2026.
//


struct LRUCache<Key: Hashable, Value>: Cache {
    private let capacity: Int
    private var order: [Key] = [] // O(n)
    private var storage: [Key: Value] = [:]
    
    init(capacity: Int) {
        precondition(capacity > 0, "LRUCache.init() capacity must be positive")
        self.capacity = capacity
        self.order.reserveCapacity(capacity)
        self.storage.reserveCapacity(capacity)
    }
    
    // MARK: - Cache
    
    var count: Int {
        return storage.count
    }
    
    mutating func value(forKey key: Key) -> Value? {
        guard let value = storage[key] else { return nil }
        guard let index = order.firstIndex(of: key) else { return nil }
        
        order.remove(at: index)
        order.insert(key, at: 0)
        return value
    }
    
    mutating func setValue(_ value: Value, forKey key: Key) {
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        
        if order.count == capacity {
            let removeKey = order.removeLast()
            storage.removeValue(forKey: removeKey)
        }
        
        order.insert(key, at: 0)
        storage[key] = value
    }
    
    @discardableResult
    mutating func removeValue(forKey key: Key) -> Value? {
        guard storage[key] != nil else { return nil }
        guard let index = order.firstIndex(of: key) else { return nil }
        
        order.remove(at: index)
        return storage.removeValue(forKey: key)
    }
}

// MARK: - Sequence
extension LRUCache: Sequence {
    typealias Element = (key: Key, value: Value)
    
    struct Iterator: IteratorProtocol {
        fileprivate var keys: IndexingIterator<[Key]>
        fileprivate let storage: [Key: Value]
        
        mutating func next() -> Element? {
            guard let key = keys.next() else { return nil }
            guard let value = storage[key] else { return nil }
            return (key, value)
        }
    }
    
    func makeIterator() -> Iterator {
        return Iterator(keys: order.makeIterator(), storage: storage)
    }
}

// MARK: - Sendable
extension LRUCache: Sendable where Key: Sendable, Value: Sendable {}
