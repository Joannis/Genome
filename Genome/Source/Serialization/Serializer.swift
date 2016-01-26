//
//  Serializable.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/22/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

/**
Objects that can serialize a structure of `Node` objects into file data.
*/
protocol Serializer {
    
    /**
     Initalizes a serializer with the given root node.
     - parameter data: The node to parse into file data.
     - returns: A new serializer object that will parse the given node.
     */
    init(node: Node)
    
    /**
     Serializes the node given into a file if possible.
     - returns: Data representing the node the serializer was initialized with.
     - throws: Throws a `SerializationError` if the node is unable to be serialized.
     */
    func parse() throws -> String.UnicodeScalarView
    
    /**
    Serializes the given node into a string representation of a specific file type.
    - parameter node: The node to serialize.
    - returns: The serialized data as a string.
    */
    static func serialize(node: Node) throws -> String
    
    /**
     Serializes the given node into a data representation of a specific file type.
     - parameter node: The node to serialize.
     - returns: The serialized data.
     */
    static func serialize(node: Node) throws -> String.UnicodeScalarView
    
}

extension Serializer {
    
    static func serialize(node: Node) throws -> String {
        return try String(Self(node: node).parse())
    }
    
    static func serialize(node: Node) throws -> String.UnicodeScalarView {
        return try Self(node: node).parse()
    }
    
}