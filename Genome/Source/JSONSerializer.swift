//
//  JSONSerializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/23/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

extension BasicMappable {
    
    func jsonRepresentatation() throws -> String {
        return try JSONSerializer().serialize(self.nodeRepresentation())
    }
    
}

class JSONSerializer: Serializer {
    
    func serialize(node: Node) throws -> String {
        return ""
    }
    
    func serialize(node: Node) throws -> [UInt8] {
        return []
    }
    
}