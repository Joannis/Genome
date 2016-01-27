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
        let nodeRep = try self.nodeRepresentation()
        return try String(JSONSerializer(node: nodeRep).parse())
    }
    
}

public class JSONSerializer: Serializer {
    
    // MARK: Properties
    
    /// Whether this serializer will pretty print output or not.
    public let prettyPrint: Bool
    
    /// What line endings should the pretty printer use
    public let lineEndings: LineEndings
    
    /// The root node.
    private let rootNode: Node
    
    /// The output string.
    private var output: String = ""
    
    // MARK: Initalization
    
    required public init(node: Node) {
        self.rootNode = node
        self.prettyPrint = false
        self.lineEndings = .Unix
    }
    
    /**
     Create a JSON serializer with the provided properties.
     - parameter node: The root node to convert to JSON.
     - parameter prettyPrint: Whether to print newlines and spaces to make the output easier to read.
     - parameter lineEndings: The type of newline character to use.
     */
    public init(node: Node, prettyPrint: Bool, lineEndings: LineEndings) {
        self.prettyPrint = prettyPrint
        self.rootNode = node
        self.lineEndings = lineEndings
    }
    
    // MARK: Serialize
    
    func parse() throws -> String.UnicodeScalarView {
        try serializeValue(rootNode)
        return output.unicodeScalars
    }
    
    // Calles the correct serializer based on the node's type.
    private func serializeValue(value: Node, indentLevel: Int = 0) throws {
        switch value {
        case .NumberValue(let nt):
            switch nt {
            case .FractionalValue(let f):
                try serializeDouble(f)
            case .IntegerValue(let i):
                serializeInt64(i)
            }
        case .NullValue:
            serializeNull()
        case .StringValue(let s):
            serializeString(s)
        case .ObjectValue(let obj):
            try serializeObject(obj, indentLevel: indentLevel)
        case .BooleanValue(let b):
            serializeBool(b)
        case .ArrayValue(let a):
            try serializeArray(a, indentLevel: indentLevel)
        }
    }
    
    /// Serializes objects.
    private func serializeObject(obj: [String : Node], indentLevel: Int = 0) throws {
        // Add the begining of an object.
        output.append(Constants.leftCurlyBracket)
        // Append a newline if necessary.
        serializeNewline()
        // Append all the keys and values.
        var i = 0
        for (key, value) in obj {
            serializeSpaces(indentLevel + 1)
            serializeString(key)
            output.append(Constants.colon)
            if prettyPrint {
                output.appendContentsOf(" ")
            }
            try serializeValue(value, indentLevel: indentLevel + 1)
            // Append a comma if necessary.
            i += 1
            if i != obj.count {
                output.append(Constants.comma)
            }
            // Add a new line if necessary.
            serializeNewline()
        }
        // End the object
        serializeSpaces(indentLevel)
        output.append(Constants.rightCurlyBracket)
    }
    
    /// Serializes arrays.
    private func serializeArray(arr: [Node], indentLevel: Int = 0) throws {
        // Start the array.
        output.append(Constants.leftSquareBracket)
        // Append a new line if necessary.
        serializeNewline()
        // Append all objects.
        var i = 0
        for val in arr {
            serializeSpaces(indentLevel + 1)
            try serializeValue(val, indentLevel: indentLevel + 1)
            // Append a comma if necessary.
            i += 1
            if i != arr.count {
                output.append(Constants.comma)
            }
            // Add a new line if necessary.
            serializeNewline()
        }
        // End the array.
        serializeSpaces(indentLevel)
        output.append(Constants.rightSquareBracket)
    }
    
    // Serialize strings.
    private func serializeString(str: String) {
        // Start the string.
        output.append(Constants.quotationMark)
        // Iterate over all the values, escaping and splitting unicode characters as necessary.
        var generator = str.unicodeScalars.generate()
        while let scalar = generator.next() {
            switch scalar.value {
            case Constants.solidus.value:
                fallthrough
            case 0x0000...0x001F:
                // Escape
                output.append(Constants.reverseSolidus)
                switch scalar {
                case Constants.tabCharacter:
                    output.appendContentsOf("t")
                case Constants.carriageReturn:
                    output.appendContentsOf("r")
                case Constants.lineFeed:
                    output.appendContentsOf("n")
                case Constants.quotationMark:
                    output.append(Constants.quotationMark)
                case Constants.backspace:
                    output.appendContentsOf("b")
                case Constants.solidus:
                    output.append(Constants.solidus)
                default:
                    // Unicode
                    output.appendContentsOf("u")
                    output.append(Constants.hexScalars[(Int(scalar.value) & 0xF000) >> 12])
                    output.append(Constants.hexScalars[(Int(scalar.value) & 0x0F00) >> 8])
                    output.append(Constants.hexScalars[(Int(scalar.value) & 0x00F0) >> 4])
                    output.append(Constants.hexScalars[(Int(scalar.value) & 0x000F) >> 0])
                }
            default:
                output.append(scalar)
            }
        }
        // End the string
        output.append(Constants.quotationMark)
    }
    
    /// Serializes a double.
    private func serializeDouble(f: Double) throws {
        if f.isNaN || f.isInfinite {
            throw SerializationError.InvalidNumber
        } else {
            // TODO: Is CustomStringConvertible for number types affected by locale?
            // TODO: Is CustomStringConvertible for Double fast?
            output.appendContentsOf(f.description)
        }
    }
    
    /// Serializes an integer.
    private func serializeInt64(i: Int64) {
        // TODO: Is CustomStringConvertible for number types affected by locale?
        output.appendContentsOf(i.description)
    }
    
    /// Serializes a boolean.
    private func serializeBool(bool: Bool) {
        switch bool {
        case true:
            output.appendContentsOf(JSONConstants.trueString)
        case false:
            output.appendContentsOf(JSONConstants.falseString)
        }
    }
    
    /// Serializes a null value.
    private func serializeNull() {
        output.appendContentsOf(JSONConstants.nullString)
    }
    
    /// Serializes a new line if necessary.
    @inline(__always)
    private final func serializeNewline() {
        if prettyPrint {
            output.appendContentsOf(lineEndings.rawValue)
        }
    }
    
    /// Serializes a series of spaces if necessary.
    @inline(__always)
    private final func serializeSpaces(indentLevel: Int = 0) {
        if prettyPrint {
            for _ in 0..<indentLevel {
                output.appendContentsOf("  ")
            }
        }
    }
}