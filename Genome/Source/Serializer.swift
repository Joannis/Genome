//
//  Serializable.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/22/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

protocol Serializer {
    
    /**
    Serializes the given node into a string representation of a specific file type.
    - parameter node: The node to serialize.
    - returns: The serialized data as a string.
    */
    func serialize(node: Node) throws -> String
    
    /**
     Serializes the given node into a data representation of a specific file type.
     - parameter node: The node to serialize.
     - returns: The serialized data.
     */
    func serialize(node: Node) throws -> [UInt8]
    
}
