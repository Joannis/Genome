//
//  SerializationError.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//

/// Errors that can be thrown by deserializers.
public enum DeserializationError: ErrorType {
    /// Some unknown error, usually indicates something not yet implemented.
    case Unknown
    /// Input data was either empty or contained only whitespace.
    case EmptyInput
    /// Some character that does not follow file specifications was found.
    case UnexpectedCharacter(lineNumber: UInt, characterNumber: UInt)
    /// A string was opened but never closed.
    case UnterminatedString
    /// Any unicode parsing errors will result in this error.
    case InvalidUnicode
    /// A keyword, like `null`, `true`, or `false` was expected but something else was in the input.
    case UnexpectedKeyword(lineNumber: UInt, characterNumber: UInt)
    /// Encountered a number that couldn't be stored, or is invalid.
    case InvalidNumber(lineNumber: UInt, characterNumber: UInt)
    /// End of file reached, not always an actual error.
    case EndOfFile
}

