//
//  CSVSerializer.swift
//  Genome
//
//  Created by McQuilkin, Brandon on 1/27/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//

extension BasicMappable {
    
    func csvRepresentatation() throws -> String {
        let nodeRep = try self.nodeRepresentation()
        return try String(CSVSerializer(node: nodeRep).parse())
    }
    
}

public class CSVSerializer: Serializer {
    
    // MARK: Properties
    
    /// Whether or not the top row is a header.
    public let addHeader: Bool
    
    /// The delimeter character to use.
    public let delimiter: UnicodeScalar
    
    /// What line endings should the pretty printer use
    public let lineEndings: LineEndings
    
    /// The root node.
    private let rootNode: Node
    
    /// The header keys.
    private var headerKeys: [String] = []
    
    /// The output string.
    private var output: String = ""
    
    /// The quotation character as a string.
    private let quotationCharacter: String = String(Constants.quotationMark)
    
    // MARK: Initalization
    
    required public init(node: Node) {
        self.rootNode = node
        self.lineEndings = .Unix
        self.addHeader = true
        self.delimiter = Constants.comma
    }
    
    /**
     Create a JSON serializer with the provided properties.
     - parameter node: The root node to convert to JSON.
     - parameter addHeader: Whether or not the top line is a header of keys.
     - parameter prettyPrint: Whether to print newlines and spaces to make the output easier to read.
     - parameter lineEndings: The type of newline character to use.
     */
    public init(node: Node, addHeader: Bool, delimiter: UnicodeScalar, lineEndings: LineEndings) {
        self.rootNode = node
        self.lineEndings = lineEndings
        self.addHeader = addHeader
        self.delimiter = delimiter
    }
    
    // MARK: Serialize
    
    func parse() throws -> String.UnicodeScalarView {
        // The top level object must be an array.
        guard case let .ArrayValue(array) = rootNode else {
            throw SerializationError.UnsupportedNodeType
        }
        try serializeMainArray(array)
        // Add the header if necessary
        if headerKeys.count > 0 {
            let header = (headerKeys.map({ generateSerializedString($0) }).joinWithSeparator(",")) + lineEndings.rawValue
            output = header + output
        }
        return output.unicodeScalars
    }
    
    // Main Array
    private func serializeMainArray(arr: [Node]) throws {
        // Append all objects.
        var isObjects: Bool?
        var i = 0
        for val in arr {
            // The main array needs to be all objects, or all non-objects.
            switch val {
            case let .ObjectValue(obj):
                if isObjects == false {
                    throw SerializationError.UnsupportedNodeType
                }
                try serializeObject(obj)
                isObjects = true
            case let .ArrayValue(arr):
                if isObjects == true {
                    throw SerializationError.UnsupportedNodeType
                }
                try serializeArray(arr)
                isObjects = false
            default:
                if isObjects == true {
                    throw SerializationError.UnsupportedNodeType
                }
                try serializeValue(val)
                isObjects = false
            }
            // Add a new line
            i += 1
            if i != arr.count {
                output.appendContentsOf(lineEndings.rawValue)
            }
        }
        // End the array.
    }
    
    // Calles the correct serializer based on the node's type.
    private func serializeValue(value: Node) throws {
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
        case .ObjectValue:
            // Objects are not supported unless they are direct children of the main array.
            throw SerializationError.UnsupportedNodeType
        case .BooleanValue(let b):
            serializeBool(b)
        case .ArrayValue:
            throw SerializationError.UnsupportedNodeType
        }
    }
    
    /// Serializes objects.
    private func serializeObject(obj: [String : Node], indentLevel: Int = 0) throws {
        // Traverse the current header keys and serialize those objects first
        var i = 0
        for key in headerKeys {
            // Serialize the object
            if let value = obj[key] {
                try serializeValue(value)
            } else {
                try serializeValue(.NullValue)
            }
            // Add a separator
            i += 1
            if i != obj.count {
                output.append(delimiter)
            }
        }
        // Now serialize new objects
        let filteredObject = obj.filter({ !headerKeys.contains($0.0) })
        for (key, value) in filteredObject {
            // Add the key
            headerKeys.append(key)
            // Add the new object
            try serializeValue(value)
            // Add a separator
            i += 1
            if i != obj.count {
                output.append(delimiter)
            }
        }
    }
    
    /// Serializes arrays.
    private func serializeArray(arr: [Node]) throws {
        // Append all objects.
        var i = 0
        for val in arr {
            try serializeValue(val)
            // Add a comma if necessary
            i += 1
            if i != arr.count {
                output.append(Constants.comma)
            }
        }
        // End the array.
    }
    
    // Serialize nulls.
    private func serializeNull() {
        output.appendContentsOf(CSVConstants.nullString)
    }
    
    // Serialize strings.
    private func serializeString(str: String) {
        // The only characters that need to be escaped is the " character and newlines.
        output.appendContentsOf(generateSerializedString(str))
    }
    
    /// Serializes a double.
    private func serializeDouble(f: Double) throws {
        // TODO: Is CustomStringConvertible for number types affected by locale?
        // TODO: Is CustomStringConvertible for Double fast?
        // Accept NaN or Infinity
        output.appendContentsOf(f.description)
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
            output.appendContentsOf(CSVConstants.trueString)
        case false:
            output.appendContentsOf(CSVConstants.falseString)
        }
    }
    
    /// Serializes a series of spaces if necessary.
    @inline(__always)
    private final func generateSerializedString(str: String) -> String {
        if str.containsString(quotationCharacter) || str.containsString(LineEndings.Unix.rawValue) || str.containsString(LineEndings.Windows.rawValue) {
            return "\"" + str.stringByReplacingOccurrencesOfString("\"", withString: "\"\"") + "\""
        } else {
            return str
        }
    }
}