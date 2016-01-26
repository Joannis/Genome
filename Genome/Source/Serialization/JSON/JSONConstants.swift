//
//  JSONConstants.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/25/16.
//  Copyright © 2016 lowriDevs. All rights reserved.
//

internal struct JSONConstants {
    
    internal static let trueToken = [UnicodeScalar]("true".unicodeScalars)
    internal static let falseToken = [UnicodeScalar]("false".unicodeScalars)
    internal static let nullToken = [UnicodeScalar]("null".unicodeScalars)
    
    internal static let escapeMap = [
        "/".unicodeScalars.first!: Constants.solidus,
        "b".unicodeScalars.first!: Constants.backspace,
        "f".unicodeScalars.first!: Constants.formFeed,
        "n".unicodeScalars.first!: Constants.lineFeed,
        "r".unicodeScalars.first!: Constants.carriageReturn,
        "t".unicodeScalars.first!: Constants.tabCharacter
    ]
    
}
