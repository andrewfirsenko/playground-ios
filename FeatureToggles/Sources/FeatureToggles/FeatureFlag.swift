//
//  FeatureFlag.swift
//  FeatureToggles
//
//  Created by Andrew on 05.11.2026.
//


struct FeatureFlag<Value: FlagValue>: Sendable {
    let key: String
    let defaultValue: Value
    
    init(_ key: String, default defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}
