//
//  NodeNumberType.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

// MARK: NodeNumberType

/**
A node object that represents a number.

**Possible Values**
- IntegerValue: An integer (`Int` or `UInt`.)
- FractionalValue: A number with a fractional component. (`Double` or `Float`.)
*/
public enum NodeNumberType {
    /// An integer (`Int` or `UInt`.)
    case IntegerValue(Int64)
    /// A number with a fractional component. (`Double` or `Float`.)
    case FractionalValue(Double)
}

// MARK: String Convertable

extension NodeNumberType: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case let .IntegerValue(integer):
            return integer.description
        case let .FractionalValue(decimal):
            return decimal.description
        }
    }
    
    public var debugDescription: String {
        switch self {
        case let .IntegerValue(integer):
            return integer.description
        case let .FractionalValue(decimal):
            return decimal.description
        }
    }
}

// MARK: Equatable

extension NodeNumberType: Equatable {}

public func ==(lhs: NodeNumberType, rhs: NodeNumberType) -> Bool {
    switch (lhs, rhs) {
    case (let .IntegerValue(l), let .IntegerValue(r)):
        return l == r
    case (let .FractionalValue(l), let .FractionalValue(r)):
        return l == r
    default:
        return false
    }
}