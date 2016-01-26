//
//  Deserializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/22/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

/**
Objects that can deserialize file data into a structure of `Node` objects.
*/
protocol Deserializer {
    
    /**
    Initalizes a deserializer with the given data.
    - parameter data: The data to parse into a node.
    - returns: A new deserializer object that will parse the given data.
    */
    init(data: String.UnicodeScalarView)
    
    /**
    Deserializes the data given into a data node if possible.
    - returns: A node representing the data the deserializer was initialized with.
    - throws: Throws a `DeserializationError` if the data is unable to be deserialized.
    */
    func parse() throws -> Node
    
    /**
     Deserializes the given string data into a node.
     - parameter data: The data to deserialize.
     - returns: The node representation of the data.
     - throws: Throws a `DeserializationError` if the data is unable to be deserialized.
     */
    static func deserialize(data: String) throws -> Node
    
    /**
    Deserializes the given data into a node.
    - parameter data: The data to deserialize.
    - returns: The node representation of the data.
    - throws: Throws a `DeserializationError` if the data is unable to be deserialized.
    */
    static func deserialize(data: String.UnicodeScalarView) throws -> Node
    
}

extension Deserializer {
    
    static func deserialize(data: String) throws -> Node {
        return try Self(data: data.unicodeScalars).parse()
    }
    
    static func deserialize(data: String.UnicodeScalarView) throws -> Node {
        return try Self(data: data).parse()
    }
    
}