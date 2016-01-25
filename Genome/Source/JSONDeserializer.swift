//
//  JSONDeserializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/23/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

extension BasicMappable {
    
    mutating func sequenceFromJson(string: String) throws {
        if let node = try JSONDeserializer().deserialize(string) {
            try self.sequence(Map(node: node))
        }
    }
    
}

class JSONDeserializer: Deserializer {
    
    func deserialize(string: String) throws -> Node? {
        return try deserialize([UInt8](string.utf8))
    }
    
    func deserialize(data: [UInt8]) throws -> Node? {
        return Node.NullValue
    }

}

