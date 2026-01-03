//
//  TypeStructure.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

struct TypeStructure: Identifiable, Sendable {
    let id: String
    let name: String
    let properties: [TypeProperty]

    init(name: String, properties: [TypeProperty]) {
        id = name
        self.name = name
        self.properties = properties
    }
}

struct TypeProperty: Identifiable, Sendable {
    let id: String
    let name: String
    let type: String
    let isOptional: Bool
    let isArray: Bool
    let nestedTypeName: String?

    init(name: String, type: String, isOptional: Bool = false, isArray: Bool = false, nestedTypeName: String? = nil) {
        id = "\(name)_\(type)"
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.isArray = isArray
        self.nestedTypeName = nestedTypeName
    }

    var displayType: String {
        var result = type
        if isArray {
            result = "[\(result)]"
        }
        if isOptional {
            result += "?"
        }
        return result
    }
}

enum TypeStructureParser {
    static func parse(_ structureText: String) -> TypeStructure? {
        let lines = structureText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let firstLine = lines.first,
              firstLine.hasPrefix("struct "),
              let typeName = extractTypeName(from: firstLine)
        else {
            return nil
        }

        var properties: [TypeProperty] = []

        for line in lines.dropFirst() {
            if line == "}" { continue }

            if let property = parseProperty(line) {
                properties.append(property)
            }
        }

        return TypeStructure(name: typeName, properties: properties)
    }

    private static func extractTypeName(from line: String) -> String? {
        let pattern = #"struct\s+(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 1), in: line)
        else {
            return nil
        }
        return String(line[range])
    }

    private static func parseProperty(_ line: String) -> TypeProperty? {
        let pattern = #"let\s+(\w+):\s+([\w\[\]<>:,\s\?]+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))
        else {
            return nil
        }

        guard let nameRange = Range(match.range(at: 1), in: line),
              let typeRange = Range(match.range(at: 2), in: line)
        else {
            return nil
        }

        let name = String(line[nameRange])
        let fullType = String(line[typeRange]).trimmingCharacters(in: .whitespaces)

        let isOptional = fullType.hasSuffix("?")
        let typeWithoutOptional = isOptional ? String(fullType.dropLast()) : fullType

        let isArray = typeWithoutOptional.hasPrefix("[") && typeWithoutOptional.hasSuffix("]")
        let baseType: String
        let nestedTypeName: String?

        if isArray {
            let innerType = String(typeWithoutOptional.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            baseType = innerType
            nestedTypeName = isPrimitiveType(innerType) ? nil : innerType
        } else {
            let trimmedType = typeWithoutOptional.trimmingCharacters(in: .whitespaces)
            baseType = trimmedType
            nestedTypeName = isPrimitiveType(trimmedType) ? nil : trimmedType
        }

        return TypeProperty(
            name: name,
            type: baseType,
            isOptional: isOptional,
            isArray: isArray,
            nestedTypeName: nestedTypeName
        )
    }

    private static func isPrimitiveType(_ type: String) -> Bool {
        let primitives = ["Int", "String", "Double", "Bool", "Float", "Int64", "Int32", "UInt"]
        return primitives.contains(type)
    }
}
