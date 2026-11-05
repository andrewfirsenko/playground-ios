//
//  FlagValue.swift
//  FeatureToggles
//
//  Created by Andrew on 05.11.2026.
//


protocol FlagValue: Sendable, Equatable {
    init?(rawFlag: RawFlagValue)
    var rawFlag: RawFlagValue { get }
}

// MARK: - Values

extension Bool: FlagValue {
    init?(rawFlag: RawFlagValue) {
        guard case let .bool(value) = rawFlag else {
            return nil
        }
        self = value
    }
    
    var rawFlag: RawFlagValue {
        return .bool(self)
    }
}

extension Int: FlagValue {
    init?(rawFlag: RawFlagValue) {
        guard case let .int(value) = rawFlag else {
            return nil
        }
        self = value
    }
    
    var rawFlag: RawFlagValue {
        return .int(self)
    }
}

extension Double: FlagValue {
    init?(rawFlag: RawFlagValue) {
        switch rawFlag {
        case .int(let int):
            guard let double = Double(exactly: int) else {
                return nil
            }
            self = double
        case .double(let double):
            self = double
        default:
            return nil
        }
    }
    
    var rawFlag: RawFlagValue {
        return .double(self)
    }
}

extension String: FlagValue {
    init?(rawFlag: RawFlagValue) {
        guard case let .string(value) = rawFlag else {
            return nil
        }
        self = value
    }
    
    var rawFlag: RawFlagValue {
        return .string(self)
    }
}

// MARK: - RawRepresentable

extension FlagValue where Self: RawRepresentable, RawValue: FlagValue {
    init?(rawFlag: RawFlagValue) {
        guard let rawValue = RawValue(rawFlag: rawFlag) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
    
    var rawFlag: RawFlagValue {
        return rawValue.rawFlag
    }
}

// MARK: - Array

extension Array: FlagValue where Element: FlagValue {
    init?(rawFlag: RawFlagValue) {
        guard case let .array(array) = rawFlag else {
            return nil
        }
        
        var elements: [Element] = []
        elements.reserveCapacity(array.count)
        
        for rawFlagValue in array {
            guard let element = Element(rawFlag: rawFlagValue) else {
                return nil
            }
            elements.append(element)
        }
        
        self.init(elements)
    }
    
    var rawFlag: RawFlagValue {
        return .array(self.map { $0.rawFlag })
    }
}
