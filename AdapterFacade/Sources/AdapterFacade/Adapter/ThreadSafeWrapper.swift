//
//  ThreadSafeWrapper.swift
//  AdapterFacade
//
//  Created by Andrew on 25.10.2026.
//

import Foundation

final class ThreadSafeWrapper<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var innerValue: T
    
    init(_ value: T) {
        self.innerValue = value
    }
    
    var value: T {
        lock.lock()
        defer { lock.unlock() }
        return innerValue
    }
    
    func mutate(_ mutation: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        mutation(&innerValue)
    }
}
