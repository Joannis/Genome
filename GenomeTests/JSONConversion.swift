//
//  JSONConversion.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2016 lowriDevs. All rights reserved.
//

import XCTest

@testable import Genome

class JSONConversionTest: XCTestCase {
    
    let testObject: Node = Node.ObjectValue([
        "unescapedString": .StringValue("The quick brown fox jumped over the lazy dog."),
        "escapingString": .StringValue("\t\r\n\u{0C}\u{08}/\\\""),
        "unicodeCharacter": .StringValue("😀"),
        "integer": .NumberValue(.IntegerValue(3)),
        "negativeInteger": .NumberValue(.IntegerValue(-5)),
        "largeInteger": .NumberValue(.FractionalValue(70000)),
        "decimal": .NumberValue(.FractionalValue(2.11)),
        "negativeDecimal": .NumberValue(.FractionalValue(-6.59)),
        "exponentedDecimal": .NumberValue(.FractionalValue(1.23)),
        "decimalWithExponent": .NumberValue(.FractionalValue(4560)),
        "justDecimal": .NumberValue(.FractionalValue(0.17)),
        "array": .ArrayValue([.StringValue("A"), .StringValue("B"), .StringValue("C"), .StringValue("D")]),
        "subObject": .ObjectValue(["a": .StringValue("A"), "b": .StringValue("B"), "c": .StringValue("C"), "d": .StringValue("D")]),
        "true": .BooleanValue(true),
        "false": .BooleanValue(false),
        "null": .NullValue
    ])
    
    func testDeserialization() {
        let dataPath = NSBundle.mainBundle().pathForResource("Test", ofType: "json")!
        let rawData = try! NSString(contentsOfFile: dataPath, encoding: NSUTF8StringEncoding)
        let data = try! JSONDeserializer.deserialize(rawData as String)
        XCTAssert(data == testObject)
    }
    
}