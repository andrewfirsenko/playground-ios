//
//  ThreadSafeWrapper.swift
//  AdapterFacade
//
//  Created by Andrew on 25.10.2026.
//


final class ThreadSafeWrapper<T>: @unchecked Sendable {
    private var lock = NSLock()
    private var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    func mutate(_ mutation: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        mutation(&value)
    }
}