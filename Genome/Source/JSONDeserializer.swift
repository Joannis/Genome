//
//  JSONDeserializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/23/16.
//  Copyright © 2015 Tyrone Trevorrow. All rights reserved.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

// MARK: BasicMappable JSON Extension

extension BasicMappable {
    
    /**
    Deserializes the given JSON string and populates the objects properties from the values found in the JSON data.
    - parameter string: The JSON string to deserialize.
    - throws: Throws a `DeserializationError` if the data is unable to be deserialized.
    */
    public mutating func sequenceFromJson(string: String) throws {
        let node = try JSONDeserializer.deserialize(string)
        try self.sequence(Map(node: node))
    }
    
}

// MARK: JSONDeserializer

/**
Deserializes JSON data into a `Node` representation.

- note: This is a strict parser implementing [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).
Being strict, it doesn't support common JSON extensions such as comments.
*/
public class JSONDeserializer: Deserializer {
    
    // MARK: Properties
    
    // The current line number
    private var lineNumber: UInt = 0
    // The current character number
    private var charNumber: UInt = 0
    // The current scalar.
    private var scalar: UnicodeScalar!
    /// The data being parsed by the deserializer.
    private var data: String.UnicodeScalarView?
    /// A generator that iterates of the te data to be deserialized.
    private var generator: String.UnicodeScalarView.Generator
    /// Protects against line feed hacks.
    private var crlfHack: Bool = false
    
    // MARK: Initalization
    
    required public init(data: String.UnicodeScalarView) {
        self.data = data
        self.generator = data.generate()
    }
    
    // MARK: Deserialization
    
    func parse() throws -> Node {
        do {
            try nextScalar()
            let value = try nextValue()
            do {
                try nextScalar()
                if scalar == Constants.tabCharacter || scalar == Constants.lineFeed || scalar == Constants.carriageReturn || scalar == Constants.space {
                    // Skip to EOF or the next token
                    try skipToNextToken()
                    // If we get this far some token was found ...
                    throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                } else {
                    // There's some weird character at the end of the file...
                    throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                }
            } catch DeserializationError.EndOfFile {
                return value
            }
        } catch DeserializationError.EndOfFile {
            throw DeserializationError.EmptyInput
        }
    }
    
    /// Moves the parser's "index" to the next character in the sequence.
    private func nextScalar() throws {
        // If there is a next character
        if let sc = generator.next() {
            // Set the current scalar to the next one.
            scalar = sc
            // Increment which character we are on.
            charNumber += 1
            // If the next character is not a line feed, and a CRLF hack has been ongoing, end it.
            if crlfHack == true && sc != Constants.lineFeed {
                crlfHack = false
            }
        } else {
            // We reached the end of the file.
            throw DeserializationError.EndOfFile
        }
    }
    
    /// Skips any whitespace before the next token.
    private func skipToNextToken() throws {
        var scalarValue = UnicodeScalar(scalar.value)
        
        // If the next character is not whitespace, it is unexpected.
        if scalarValue != Constants.tabCharacter && scalarValue != Constants.lineFeed && scalarValue != Constants.carriageReturn && scalarValue != Constants.space {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        
        // Iterate over all whitespace characters until a new token is reached.
        while scalarValue == Constants.tabCharacter || scalarValue == Constants.lineFeed || scalarValue == Constants.carriageReturn || scalarValue == Constants.space {

            if scalar == Constants.carriageReturn || scalar == Constants.lineFeed {
                
                // End the CLRF hack.
                if crlfHack == true && scalar == Constants.lineFeed {
                    crlfHack = false
                    charNumber = 0
                } else {
                    // Check to see if we are starting a series of
                    if (scalar == Constants.carriageReturn) {
                        crlfHack = true
                    }
                    // Add to the new line count.
                    lineNumber = lineNumber + 1
                    charNumber = 0
                }
            }
            
            try nextScalar()
            scalarValue = UnicodeScalar(scalar.value)
        }
    }
    
    /**
    Retreives the next scalars and returns an array.
    - parameter count: The number of scalars to retreive.
    - returns: An array of scalars.
    */
    private func nextScalars(count: UInt) throws -> [UnicodeScalar] {
        var values: [UnicodeScalar] = []
        values.reserveCapacity(Int(count))
        for _ in 0..<count {
            try nextScalar()
            values.append(scalar)
        }
        return values
    }
    
    // MARK: - Main Parse Loop
    
    /// Parse the next value in the JSON data.
    func nextValue() throws -> Node {
        // Check to see if the next scalar is whitespace
        if scalar == Constants.tabCharacter || scalar == Constants.lineFeed || scalar == Constants.carriageReturn || scalar == Constants.space {
            try skipToNextToken()
        }
        // Iterate over the possible values
        switch scalar {
        case Constants.leftCurlyBracket:
            return try nextObject()
        case Constants.leftSquareBracket:
            return try nextArray()
        case Constants.quotationMark:
            return try nextString()
        case JSONConstants.trueToken[0], JSONConstants.falseToken[0]:
            return try nextBool()
        case JSONConstants.nullToken[0]:
            return try nextNull()
        case "0".unicodeScalars.first!..."9".unicodeScalars.first!, Constants.negativeScalar, Constants.decimalScalar:
            return try nextNumber()
        default:
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
    }
    
    // MARK: - Object Parsing
    
    /// Parses object data.
    func nextObject() throws -> Node {
        // Check to see that the next token is an opening curly brace.
        if scalar != Constants.leftCurlyBracket {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        // Skip the opening curly brace.
        try nextScalar()
        
        // Object storage.
        var dict = [String : Node]()
        
        // Check to see if we have an empty object.
        if scalar == Constants.rightCurlyBracket {
            return Node.ObjectValue(dict)
        }
        
        // Iterate over the objects.
        outerLoop: repeat {
            // Skip whitespace.
            if scalar == Constants.tabCharacter || scalar == Constants.lineFeed || scalar == Constants.carriageReturn || scalar == Constants.space {
                try skipToNextToken()
            }
            // Get the key.
            let jsonString = try nextString()
            // Skip the end quotation character.
            try nextScalar()
            
            // Skip whitespace.
            if scalar == Constants.tabCharacter || scalar == Constants.lineFeed || scalar == Constants.carriageReturn || scalar == Constants.space {
                try skipToNextToken()
            }
            
            // If the next character is not a colon, we do not have a valid object.
            if scalar != Constants.colon {
                throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
            // Skip the ':'.
            try nextScalar()
            
            // Skip the closing character for all values except number, which doesn't have one.
            let value = try nextValue()
            switch value {
            case .NumberValue:
                break
            default:
                try nextScalar()
            }
            
            // Skip to the next token.
            if scalar == Constants.tabCharacter || scalar == Constants.lineFeed || scalar == Constants.carriageReturn || scalar == Constants.space {
                try skipToNextToken()
            }
            
            // Add the object to the dictionary.
            let key = jsonString.stringValue!
            dict[key] = value
            
            // Check to see if we reached the end of the object, or if there is another key/value pair.
            switch scalar {
            case Constants.rightCurlyBracket:
                break outerLoop
            case Constants.comma:
                try nextScalar()
            default:
                throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
            
        } while true // We only manually break the loop.
        
        return Node.ObjectValue(dict)
    }

    /// Parses array data
    private func nextArray() throws -> Node {
        // Check to see that the next token is an opening square bracket.
        if scalar != Constants.leftSquareBracket {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        // Skip the opening bracket
        try nextScalar()
        
        // Array storage
        var arr: [Node] = []
        
        // Check to see if the array is empty.
        if scalar == Constants.rightSquareBracket {
            // Empty array
            return .ArrayValue(arr)
        }
        
        // Iterate over the objects.
        outerLoop: repeat {
            // Retreive the next value.
            let value = try nextValue()
            arr.append(value)
            
            // Skip the closing character for all values except number, which doesn't have one.
            switch value {
            case .NumberValue:
                break
            default:
                try nextScalar()
            }
            
            // Skip whitespace.
            if scalar == Constants.tabCharacter || scalar == Constants.lineFeed || scalar == Constants.carriageReturn || scalar == Constants.space {
                try skipToNextToken()
            }
            
            // Check to see if we reached the end of the array, or if there is another value.
            switch scalar {
            case Constants.rightSquareBracket:
                break outerLoop
            case Constants.comma:
                try nextScalar()
            default:
                throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
        } while true // We only manually break the loop.
        
        return .ArrayValue(arr)
    }
    
    /// Parses string data
    private func nextString() throws -> Node {
        // Check to see that the next token is a quotation mark.
        if scalar != Constants.quotationMark {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        // Skip opening quotation
        try nextScalar()
        
        // String storage
        var strBuilder = ""
        // Whether or not the next character will be escaped.
        var escaping = false
        
        // Iterate over the objects.
        outerLoop: repeat {
            // First we should deal with the escape character and the terminating quote
            switch scalar {
            case Constants.reverseSolidus:
                // Escape character
                if escaping {
                    // Escaping the escape char
                    strBuilder.append(Constants.reverseSolidus)
                }
                escaping = !escaping
                try nextScalar()
            case Constants.quotationMark:
                // Is this quotation mark escaped, or did we reach the end?
                if escaping {
                    strBuilder.append(Constants.quotationMark)
                    escaping = false
                    try nextScalar()
                } else {
                    break outerLoop
                }
            default:
                // Continue parsing the string.
                if escaping {
                    // Handle all the different escape characters
                    if let s = JSONConstants.escapeMap[scalar] {
                        strBuilder.append(s)
                        try nextScalar()
                    } else if scalar == "u".unicodeScalars.first! {
                        // Handle unicode
                        let escapedUnicodeValue = try nextUnicodeEscape()
                        strBuilder.append(UnicodeScalar(escapedUnicodeValue))
                        try nextScalar()
                    }
                    escaping = false
                } else {
                    // Simple append
                    strBuilder.append(scalar)
                    try nextScalar()
                }
            }
        } while true // We only manually break the loop.
        
        return .StringValue(strBuilder)
    }
    
    /// Parses a unicode character.
    private func nextUnicodeEscape() throws -> UInt32 {
        // Check to see that the token is a unicode mark.
        if scalar != "u".unicodeScalars.first! {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        
        // The read character.
        var readScalar = UInt32(0)
        // Iterate over the next three characters
        for _ in 0...3 {
            readScalar = readScalar * 16
            try nextScalar()
            
            // Convert from hex.
            if ("0".unicodeScalars.first!..."9".unicodeScalars.first!).contains(scalar) {
                readScalar = readScalar + UInt32(scalar.value - "0".unicodeScalars.first!.value)
            } else if ("a".unicodeScalars.first!..."f".unicodeScalars.first!).contains(scalar) {
                let aScalarVal = "a".unicodeScalars.first!.value
                let hexVal = scalar.value - aScalarVal
                let hexScalarVal = hexVal + 10
                readScalar = readScalar + hexScalarVal
            } else if ("A".unicodeScalars.first!..."F".unicodeScalars.first!).contains(scalar) {
                let aScalarVal = "A".unicodeScalars.first!.value
                let hexVal = scalar.value - aScalarVal
                let hexScalarVal = hexVal + 10
                readScalar = readScalar + hexScalarVal
            } else {
                throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
        }
        
        if readScalar >= 0xD800 && readScalar <= 0xDBFF {
            // UTF-16 surrogate pair
            // The next character MUST be the other half of the surrogate pair
            // Otherwise it's a unicode error
            do {
                try nextScalar()
                if scalar != Constants.reverseSolidus {
                    throw DeserializationError.InvalidUnicode
                }
                try nextScalar()
                let secondScalar = try nextUnicodeEscape()
                if secondScalar < 0xDC00 || secondScalar > 0xDFFF {
                    throw DeserializationError.InvalidUnicode
                }
                let actualScalar = (readScalar - 0xD800) * 0x400 + (secondScalar - 0xDC00) + 0x10000
                return actualScalar
            } catch DeserializationError.UnexpectedCharacter {
                throw DeserializationError.InvalidUnicode
            }
        }
        
        return readScalar
    }
    
    /// Parses a number
    private func nextNumber() throws -> Node {
        var isNegative = false
        var hasDecimal = false
        var hasDigits = false
        var hasExponent = false
        var positiveExponent = false
        var exponent = 0
        var integer: UInt64 = 0
        var decimal: Int64 = 0
        var divisor: Double = 10
        let lineNumAtStart = lineNumber
        let charNumAtStart = charNumber
        
        do {
            outerLoop: repeat {
                switch scalar {
                case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                    // We started with numbers.
                    hasDigits = true
                    // Process differently wether or not the number is a decimal.
                    if hasDecimal {
                        decimal *= 10
                        decimal += Int64(scalar.value - Constants.zeroScalar.value)
                        divisor *= 10
                    } else {
                        integer *= 10
                        integer += UInt64(scalar.value - Constants.zeroScalar.value)
                    }
                    try nextScalar()
                case Constants.negativeScalar:
                    // A number should only be marked negative once.
                    if hasDigits || hasDecimal || hasExponent || isNegative {
                        throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        isNegative = true
                    }
                    try nextScalar()
                case Constants.decimalScalar:
                    // A number should only have one decimal place.
                    if hasDecimal {
                        throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        hasDecimal = true
                    }
                    try nextScalar()
                case "e".unicodeScalars.first!,"E".unicodeScalars.first!:
                    // A number can't have two exponents.
                    if hasExponent {
                        throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        hasExponent = true
                    }
                    try nextScalar()
                    // Determine if the exponenet is positive or negative.
                    switch scalar {
                    case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                        positiveExponent = true
                    case Constants.plusScalar:
                        positiveExponent = true
                        try nextScalar()
                    case Constants.negativeScalar:
                        positiveExponent = false
                        try nextScalar()
                    default:
                        throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    }
                    // Iterate over the numbers in the exponent.
                    exponentLoop: repeat {
                        if scalar.value >= Constants.zeroScalar.value && scalar.value <= "9".unicodeScalars.first!.value {
                            exponent *= 10
                            exponent += Int(scalar.value - Constants.zeroScalar.value)
                            try nextScalar()
                        } else {
                            break exponentLoop
                        }
                    } while true // We only manually break the loop.
                default:
                    break outerLoop
                }
            } while true // We only manually break the loop.
            
        } catch DeserializationError.EndOfFile {
            // This is fine
        }
        
        // If there are no digits, there is no number.
        if !hasDigits {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        
        // Create the number
        // TODO: Handle numbers too large and too small for standard types.
        // TODO: Handle numbers with exponents that become an integer.
        let sign = isNegative ? -1 : 1
        if hasDecimal || hasExponent {
            // TODO: Need to find a way that maintains decimal percision.
            // String conversion? What is the speed of that?
            // Perhaps have NumberValue always be (mantissa, exponent, sign), and convert to decimal on demand?
            divisor /= 10
            var number = Double(sign) * (Double(integer) + (Double(decimal) / divisor))
            if hasExponent {
                if positiveExponent {
                    for _ in 1...exponent {
                        number *= Double(10)
                    }
                } else {
                    for _ in 1...exponent {
                        number /= Double(10)
                    }
                }
            }
            return .NumberValue(NodeNumberType.FractionalValue(number))
        } else {
            var number: Int64
            if isNegative {
                if integer > UInt64(Int64.max) + 1 {
                    throw DeserializationError.InvalidNumber(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
                } else if integer == UInt64(Int64.max) + 1 {
                    number = Int64.min
                } else {
                    number = Int64(integer) * -1
                }
            } else {
                if integer > UInt64(Int64.max) {
                    throw DeserializationError.InvalidNumber(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
                } else {
                    number = Int64(integer)
                }
            }
            return .NumberValue(NodeNumberType.IntegerValue(number))
        }
    }
    
    /// Parses a boolean object
    private func nextBool() throws -> Node {
        var expectedWord: [UnicodeScalar]
        var expectedBool: Bool
        let lineNumAtStart = lineNumber
        let charNumAtStart = charNumber
        
        // Which bool is it?
        if scalar == JSONConstants.trueToken[0] {
            expectedWord = JSONConstants.trueToken
            expectedBool = true
        } else if scalar == JSONConstants.falseToken[0] {
            expectedWord = JSONConstants.falseToken
            expectedBool = false
        } else {
            throw DeserializationError.UnexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        
        // Check to see if the full boolean text is there.
        do {
            let word = try [scalar] + nextScalars(UInt(expectedWord.count - 1))
            if word != expectedWord {
                throw DeserializationError.UnexpectedKeyword(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
            }
        } catch DeserializationError.EndOfFile {
            throw DeserializationError.UnexpectedKeyword(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
        }
        return .BooleanValue(expectedBool)
    }
    
    func nextNull() throws -> Node {
        let word = try [scalar] + nextScalars(3)
        if word != JSONConstants.nullToken {
            throw DeserializationError.UnexpectedKeyword(lineNumber: lineNumber, characterNumber: charNumber-4)
        }
        return .NullValue
    }
}

