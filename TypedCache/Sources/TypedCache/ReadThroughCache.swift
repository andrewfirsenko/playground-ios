//
//  ReadThroughCache.swift
//  TypedCache
//
//  Created by Andrew on 31.10.2026.
//


actor ReadThroughCache<C: Cache, L: DataLoader> where C.Key == L.Key, C.Value == L.Value {
    typealias Key = C.Key
    typealias Value = C.Value
    typealias Failure = L.Failure
    
    private var cache: C
    private let loader: L
    
    init(cache: C, loader: L) {
        self.cache = cache
        self.loader = loader
    }
    
    func value(forKey key: Key) async throws(Failure) -> Value {
        if let cacheValue = cache.value(forKey: key) {
            return cacheValue
        }
        
        let value = try await loader.load(key)
        cache.setValue(value, forKey: key)
        
        return value
    }
    
    func invalidate(_ key: Key) {
        cache.removeValue(forKey: key)
    }
}