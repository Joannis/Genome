po test//
//  CSVConversion.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/28/16.
//  Copyright © 2016 lowriDevs. All rights reserved.
//

import XCTest

@testable import Genome

class CSVConversionTest: XCTestCase {
    
    let testObjectParsing: Node = Node.ArrayValue([
        .ObjectValue(["Property 1": .StringValue("A"), "Property 2": .StringValue("B"), "Property 3": .StringValue("C"), "Property 4": .StringValue("D")]),
        .ObjectValue(["Property 1": .StringValue("A"), "Property 2": .StringValue("B"), "Property 3": .StringValue("C"), "Property 4": .StringValue("D")]),
        .ObjectValue(["Property 1": .StringValue("A"), "Property 2": .StringValue("B"), "Property 3": .StringValue("C"), "Property 4": .StringValue("D")]),
        .ObjectValue(["Property 1": .StringValue("A\"A"), "Property 2": .StringValue("B\"B"), "Property 3": .StringValue("C\"C"), "Property 4": .StringValue("D\"D")]),
        .ObjectValue(["Property 1": .StringValue("\""), "Property 2": .StringValue("\"\""), "Property 3": .StringValue("\"\"\""), "Property 4": .StringValue("\"\"\"\"")]),
        .ObjectValue(["Property 1": .StringValue("A\nA"),  "Property 2": .StringValue("B\nB"), "Property 3": .StringValue("C\nC"), "Property 4": .StringValue("D\nD")]),
        .ObjectValue(["Property 1": .StringValue(" \"A"), "Property 2": .StringValue("B\""), "Property 3": .StringValue("C\"\""), "Property 4": .StringValue("D")])
        ])
    
    let testObjectMapping: Node = Node.ArrayValue([
        .ObjectValue(["true": .BooleanValue(true), "false": .BooleanValue(false), "null": .NullValue, "number": .NumberValue(.IntegerValue(2))]),
        .ObjectValue(["true": .BooleanValue(true), "false": .BooleanValue(false), "null": .NullValue, "number": .NumberValue(.FractionalValue(2.5))]),
        .ObjectValue(["true": .BooleanValue(true), "false": .BooleanValue(false), "null": .NullValue, "number": .NumberValue(.FractionalValue(3000.0))]),
        .ObjectValue(["true": .BooleanValue(true), "false": .BooleanValue(false), "null": .NullValue, "number": .NumberValue(.FractionalValue(440.0))]),
        .ObjectValue(["true": .BooleanValue(true), "false": .BooleanValue(false), "null": .NullValue, "number": .NumberValue(.FractionalValue(0.04))])
        ])
    
    let testArray: Node = Node.ArrayValue([
        .ArrayValue([.StringValue("A"), .StringValue("B"), .StringValue("C"), .StringValue("D")]),
        .ArrayValue([.StringValue("E"), .StringValue("F"), .StringValue("G"), .StringValue("H")]),
        .ArrayValue([.StringValue("I"), .StringValue("J"), .StringValue("K"), .StringValue("L")]),
        .ArrayValue([.StringValue("M"), .StringValue("N"), .StringValue("O"), .StringValue("P")]),
        .ArrayValue([.StringValue("Q"), .StringValue("R"), .StringValue("S"), .StringValue("T")]),
        .ArrayValue([.StringValue("U"), .StringValue("V"), .StringValue("W"), .StringValue("X")]),
        .ArrayValue([.StringValue("Y"), .StringValue("Z")])
        ])
    
    func testObjectParsingDeserialization() {
        let dataPath = NSBundle.mainBundle().pathForResource("Object-Parsing", ofType: "csv")!
        let rawData = try! NSString(contentsOfFile: dataPath, encoding: NSUTF8StringEncoding) as String
        let data = try! CSVDeserializer.deserialize(rawData)
        XCTAssert(data == testObjectParsing)
    }
    
    func testObjectMappingDeserialization() {
        let dataPath = NSBundle.mainBundle().pathForResource("Object-Mapping", ofType: "csv")!
        let rawData = try! NSString(contentsOfFile: dataPath, encoding: NSUTF8StringEncoding) as String
        let data = try! CSVDeserializer.deserialize(rawData)
        XCTAssert(data == testObjectMapping)
    }
    
    func testArrayDeserialization() {
        let dataPath = NSBundle.mainBundle().pathForResource("Array", ofType: "csv")!
        let rawData = try! NSString(contentsOfFile: dataPath, encoding: NSUTF8StringEncoding) as String
        let data = try! CSVDeserializer(data: rawData.unicodeScalars, containsHeader: false, mapValues: true).parse()
        XCTAssert(data == testArray)
    }
    
    func testObjectParsingSerialization() {
        let data: String = try! CSVSerializer.serialize(testObjectParsing)
        // TODO: A better way to test this is needed, as dictionary order is not guaranteed.
        let stringRepresentation = "Property 3,Property 2,Property 1,Property 4\nC,B,A,D\nC,B,A,D\nC,B,A,D\n\"C\"\"C\",\"B\"\"B\",\"A\"\"A\",\"D\"\"D\"\n\"\"\"\"\"\"\"\",\"\"\"\"\"\",\"\"\"\",\"\"\"\"\"\"\"\"\"\"\n\"C\nC\",\"B\nB\",\"A\nA\",\"D\nD\"\n\"C\"\"\"\"\",\"B\"\"\",\" \"\"A\",D"
        XCTAssert(data == stringRepresentation)
    }
    
    func testObjectMappingSerialization() {
        let data: String = try! CSVSerializer.serialize(testObjectMapping)
        // TODO: A better way to test this is needed, as dictionary order is not guaranteed.
        let stringRepresentation = "true,false,number,null\ntrue,false,2,null\ntrue,false,2.5,null\ntrue,false,3000.0,null\ntrue,false,440.0,null\ntrue,false,0.04,null"
        XCTAssert(data == stringRepresentation)
    }
    
    func testArraySerialization() {
        let data: String = try! CSVSerializer.serialize(testArray)
        // TODO: A better way to test this is needed, as dictionary order is not guaranteed.
        let stringRepresentation = "A,B,C,D\nE,F,G,H\nI,J,K,L\nM,N,O,P\nQ,R,S,T\nU,V,W,X\nY,Z"
        XCTAssert(data == stringRepresentation)
    }
    
}
