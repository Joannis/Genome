//
//  SerializationError.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

public enum DeserializationError: ErrorType {
    case Unknown
    case EmptyInput
    case UnexpectedCharacter(lineNumber: UInt, characterNumber: UInt)
    case UnterminatedString
    case InvalidUnicode
    case UnexpectedKeyword(lineNumber: UInt, characterNumber: UInt)
    case InvalidNumber(lineNumber: UInt, characterNumber: UInt)
    case EndOfFile
}

