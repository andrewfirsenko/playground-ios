//
//  DataLoader.swift
//  TypedCache
//
//  Created by Andrew on 31.10.2026.
//


protocol DataLoader: Sendable {
    associatedtype Key: Hashable & Sendable
    associatedtype Value: Sendable
    associatedtype Failure: Error
    
    func load(_ key: Key) async throws(Failure) -> Value
}


