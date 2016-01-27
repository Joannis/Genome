//
//  JSONConstants.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

internal struct JSONConstants {
    
    internal static let trueToken = [UnicodeScalar]("true".unicodeScalars)
    internal static let trueString = "true"
    internal static let falseToken = [UnicodeScalar]("false".unicodeScalars)
    internal static let falseString = "false"
    internal static let nullToken = [UnicodeScalar]("null".unicodeScalars)
    internal static let nullString = "null"
    
    internal static let escapeMap = [
        "/".unicodeScalars.first!: Constants.solidus,
        "b".unicodeScalars.first!: Constants.backspace,
        "f".unicodeScalars.first!: Constants.formFeed,
        "n".unicodeScalars.first!: Constants.lineFeed,
        "r".unicodeScalars.first!: Constants.carriageReturn,
        "t".unicodeScalars.first!: Constants.tabCharacter
    ]
    
}
