//
//  FlagProvider.swift
//  FeatureToggles
//
//  Created by Andrew on 05.11.2026.
//


protocol FlagProvider: Sendable {
    func value<V: FlagValue>(for flag: FeatureFlag<V>) -> V?
}
