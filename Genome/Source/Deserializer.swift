//
//  Deserializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/22/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

protocol Deserializer {
    
    /**
     Deserializes the given string data into a node.
     - parameter data: The data to deserialize.
     - returns: The node representation of the data.
     */
    func deserialize(data: String) throws -> Node?
    
    /**
    Deserializes the given data into a node.
    - parameter data: The data to deserialize.
    - returns: The node representation of the data.
    */
    func deserialize(data: [UInt8]) throws -> Node?
    
}