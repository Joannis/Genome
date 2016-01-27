//
//  SerializationError.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

/// Errors that can be thrown by serializers.
public enum SerializationError: ErrorType {
    /// An unknown error occured.
    case Unknown
    /// An invalid number was encountered.
    case InvalidNumber
    /// The type of node encountered is not supported by the serializer.
    case UnsupportedNodeType
}
