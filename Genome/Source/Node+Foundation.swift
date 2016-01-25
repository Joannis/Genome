//
//  Node+Foundation.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/21/16.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import Foundation

extension Node {
    
    public static func from(any: AnyObject) -> Node {
        switch any {
            // If we're coming from foundation, it will be an `NSNumber`.
            //This represents double, integer, and boolean.
        case let number as NSNumber:
            if Double(number.integerValue) == number.doubleValue {
                return .NumberValue(.IntegerValue(Int64(number.integerValue)))
            } else {
                return .NumberValue(.FractionalValue(number.doubleValue))
            }
        case let string as String:
            return .StringValue(string)
        case let object as [String : AnyObject]:
            return from(object)
        case let array as [AnyObject]:
            return .ArrayValue(array.map(from))
        case _ as NSNull:
            return .NullValue
        default:
            fatalError("Unsupported foundation type")
        }
        return .NullValue
    }
    
    public static func from(any: [String : AnyObject]) -> Node {
        var mutable: [String : Node] = [:]
        any.forEach { key, val in
            mutable[key] = .from(val)
        }
        return .from(mutable)
    }
}
