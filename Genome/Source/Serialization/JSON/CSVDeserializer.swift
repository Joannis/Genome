//
//  CSVDeserializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/27/16.
//  Copyright © 2016 lowriDevs. All rights reserved.
//

extension BasicMappable {
    
    /**
     Deserializes the given CSV string and populates the object's properties from the values found in the CSV data.
     - parameter string: The CSV string to deserialize.
     - throws: Throws a `DeserializationError` if the data is unable to be deserialized.
     */
    public mutating func sequenceFromCsv(string: String) throws {
        let node = try CSVDeserializer.deserialize(string)
        try self.sequence(Map(node: node))
    }
    
}

/**
 Deserializes CSV data into a `Node` representation.
 
 - note: This is a parser implementing [RC-4180](https://tools.ietf.org/html/rfc4180).
 - warning: Unless otherwise specified: The parser considers the top row a header row and will create objects with the keys specified in the header. The deserializer will also attempt to map certian keywords to different values. For example "true" and "false" will be converted to booleans, and pure numbers will be converted to a numerical type.
 */
public class CSVDeserializer: Deserializer {
    
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
    /// Whether or not the top row is a header.
    private var containsHeader: Bool
    /// Whetehr or not to map keywords and numbers.
    private var mapValues: Bool
    /// The header keys if any.
    private var headerKeys: [String] = []
    
    // MARK: Initalization
    
    required public init(data: String.UnicodeScalarView) {
        self.data = data
        self.generator = data.generate()
        self.containsHeader = true
        self.mapValues = true
    }
    
    init(data: String.UnicodeScalarView, containsHeader: Bool, mapValues: Bool) {
        self.data = data
        self.generator = data.generate()
        self.containsHeader = containsHeader
        self.mapValues = mapValues
    }
    
    // MARK: Deserialization
    
    func parse() throws -> Node {
        do {
            try nextScalar()
            if containsHeader {
                try parseHeader()
            }
        } catch DeserializationError.EndOfFile {
            throw DeserializationError.EmptyInput
        }
        
        return try mainArray()
    }
    
    /// Moves the parser's "index" to the next character in the sequence.
    private func nextScalar() throws {
        // If there is a next character
        if let sc = generator.next() {
            // Set the current scalar to the next one.
            scalar = sc
            print(scalar)
            // Increment which character we are on.
            charNumber += 1
        } else {
            // We reached the end of the file.
            throw DeserializationError.EndOfFile
        }
    }
    
    // MARK: - Header
    
    /// Parses the header keys for mapping values to objects.
    private func parseHeader() throws {
        // Iterate over the header keys
        outerLoop: repeat {
            switch scalar {
            case Constants.comma:
                try nextScalar()
            case Constants.carriageReturn, Constants.lineFeed:
                break outerLoop
            default:
                if let key = try nextValue(true).stringValue {
                    headerKeys.append(key)
                }
            }
            
        } while true
    }
    
    // MARK: - Main Parse Loop
    
    /// Parses the main array of values
    private func mainArray() throws -> Node {
        var array: [Node] = []
        // Iterate over the rows
        outerLoop: repeat {
            switch scalar {
            case Constants.carriageReturn, Constants.lineFeed:
                // If an empty line, add a null value
                do {
                    array.append(.NullValue)
                    try nextScalar()
                    lineNumber += 1
                } catch DeserializationError.EndOfFile {
                    break outerLoop
                }
            default:
                do {
                    // Append the row
                    if containsHeader {
                        array.append(try nextObject())
                    } else {
                        array.append(try nextArray())
                    }
                    // Skip the new line
                    try nextScalar()
                    lineNumber += 1
                } catch DeserializationError.EndOfFile {
                    break outerLoop
                }
            }
        } while true
        
        return .ArrayValue(array)
    }
    
    /// Parses a line of values into an array.
    private func nextArray() throws -> Node {
        var array: [Node] = []
        // Iterate the columns into arrays.
        outerLoop: repeat {
            switch scalar {
            case Constants.comma:
                try nextScalar()
            case Constants.carriageReturn, Constants.lineFeed:
                break outerLoop
            default:
                do {
                    array.append(try nextValue())
                    
                    //try nextScalar()
                } catch DeserializationError.EndOfFile {
                    break outerLoop
                }
            }
            
        } while true
        
        return .ArrayValue(array)
    }
    
    /// Parses a line of values into an object.
    private func nextObject() throws -> Node {
        var object: [String: Node] = [:]
        // Iterate the columns into object values.
        var i = 0
        outerLoop: repeat {
            switch scalar {
            case Constants.comma:
                try nextScalar()
                // Iterate which key we are on.
                i += 1
                // If we surpassed the number of keys, return the object
                // TODO: Confirm that this would be expected behavior.
                if i >= headerKeys.count {
                    break outerLoop
                }
            case Constants.carriageReturn, Constants.lineFeed:
                break outerLoop
            default:
                // Add the value to the object
                do {
                    object[headerKeys[i]] = try nextValue()
                    try nextScalar()
                } catch DeserializationError.EndOfFile {
                    break outerLoop
                }
            }
        } while true
        
        return .ObjectValue(object)
    }
    
    /// Parses string data
    private func nextValue(processingHeader: Bool = false) throws -> Node {
        // Whether or not we are in a set of quotes. If we are double quotes and newlines are part of the string.
        var escaping = false
        // Check to see that the next token is a quotation mark.
        if scalar == Constants.quotationMark {
            // Skip opening quotation
            try nextScalar()
            escaping = true
        }
        
        // String storage
        var strBuilder = ""
        
        do {
            // Iterate over the objects.
            outerLoop: repeat {
                // First we should deal with the escape character and the terminating quote
                switch scalar {
                case Constants.comma:
                    if escaping {
                        // The comma is part of the string.
                        strBuilder.append(Constants.comma)
                        try nextScalar()
                    } else {
                        break outerLoop
                    }
                case Constants.lineFeed, Constants.carriageReturn:
                    if escaping {
                        // The new line is part of the string.
                        strBuilder.append(scalar)
                        try nextScalar()
                    } else {
                        break outerLoop
                    }
                case Constants.quotationMark:
                    // Is this quotation mark escaped, or did we reach the end?
                    if escaping {
                        try nextScalar()
                        if scalar == Constants.quotationMark {
                            strBuilder.append(Constants.quotationMark)
                            try nextScalar()
                        } else {
                            break outerLoop
                        }
                    } else {
                        strBuilder.append(Constants.quotationMark)
                        try nextScalar()
                    }
                default:
                    strBuilder.append(scalar)
                    try nextScalar()
                }
            } while true // We only manually break the loop.
        } catch DeserializationError.EndOfFile {
            // This is ok if we are not escaping.
            if escaping {
                throw DeserializationError.EndOfFile
            }
        }
        
        if mapValues && !processingHeader {
            return parseValue(strBuilder)
        } else {
            return .StringValue(strBuilder)
        }
    }
    
    /// Parses a string into an object if possible.
    private func parseValue(string: String) -> Node {
        if string.lowercaseString == CSVConstants.trueString {
            return .BooleanValue(true)
        } else if string.lowercaseString == CSVConstants.falseString {
            return .BooleanValue(false)
        } else if string.lowercaseString == CSVConstants.nullString {
            return .NullValue
        } else if string.characters.count > 0{
            return nextNumberOrString(string)
        } else {
            return .NullValue
        }
    }
    
    /// Parses a number if possible, otherwise returns a string.
    private func nextNumberOrString(string: String) -> Node {
        var nGenerator = string.unicodeScalars.generate()
        var nScalar: UnicodeScalar = nGenerator.next()!
        
        var isNegative = false
        var hasDecimal = false
        var hasDigits = false
        var hasExponent = false
        var positiveExponent = false
        var exponent = 0
        var integer: UInt64 = 0
        var decimal: Int64 = 0
        var divisor: Double = 10
        
        // Iterate over all the characters. If a non-numeric character is found, we have a string. Otherwise build a number.
        outerLoop: repeat {
            switch nScalar {
            case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                // We started with numbers.
                hasDigits = true
                // Process differently wether or not the number is a decimal.
                if hasDecimal {
                    decimal *= 10
                    decimal += Int64(nScalar.value - Constants.zeroScalar.value)
                    divisor *= 10
                } else {
                    integer *= 10
                    integer += UInt64(nScalar.value - Constants.zeroScalar.value)
                }
                if let newScalar = nGenerator.next() {
                    nScalar = newScalar
                } else {
                    break outerLoop
                }
            case Constants.negativeScalar:
                // A number should only be marked negative once.
                if hasDigits || hasDecimal || hasExponent || isNegative {
                    return .StringValue(string)
                } else {
                    isNegative = true
                }
                if let newScalar = nGenerator.next() {
                    nScalar = newScalar
                } else {
                    break outerLoop
                }
            case Constants.decimalScalar:
                // A number should only have one decimal place.
                if hasDecimal {
                    return .StringValue(string)
                } else {
                    hasDecimal = true
                }
                if let newScalar = nGenerator.next() {
                    nScalar = newScalar
                } else {
                    break outerLoop
                }
            case "e".unicodeScalars.first!,"E".unicodeScalars.first!:
                // A number can't have two exponents.
                if hasExponent {
                    return .StringValue(string)
                } else {
                    hasExponent = true
                }
                if let newScalar = nGenerator.next() {
                    nScalar = newScalar
                } else {
                    break outerLoop
                }
                // Determine if the exponenet is positive or negative.
                switch scalar {
                case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                    positiveExponent = true
                case Constants.plusScalar:
                    positiveExponent = true
                    if let newScalar = nGenerator.next() {
                        nScalar = newScalar
                    } else {
                        break outerLoop
                    }
                case Constants.negativeScalar:
                    positiveExponent = false
                    if let newScalar = nGenerator.next() {
                        nScalar = newScalar
                    } else {
                        break outerLoop
                    }
                default:
                    return .StringValue(string)
                }
                // Iterate over the numbers in the exponent.
                exponentLoop: repeat {
                    if nScalar.value >= Constants.zeroScalar.value && nScalar.value <= "9".unicodeScalars.first!.value {
                        exponent *= 10
                        exponent += Int(nScalar.value - Constants.zeroScalar.value)
                        if let newScalar = nGenerator.next() {
                            nScalar = newScalar
                        } else {
                            break outerLoop
                        }
                    } else {
                        break exponentLoop
                    }
                } while true // We only manually break the loop.
            default:
                break outerLoop
            }
        } while true // We only manually break the loop.
        
        // If there are no digits, there is no number.
        if !hasDigits {
            return .StringValue(string)
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
                    return .StringValue(string)
                } else if integer == UInt64(Int64.max) + 1 {
                    number = Int64.min
                } else {
                    number = Int64(integer) * -1
                }
            } else {
                if integer > UInt64(Int64.max) {
                    return .StringValue(string)
                } else {
                    number = Int64(integer)
                }
            }
            return .NumberValue(NodeNumberType.IntegerValue(number))
        }
    }
}
