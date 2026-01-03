//
//  TypeStructureResolver.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public func resolveTypeStructure(for type: Any.Type) -> String? {
    if let arrayElementType = extractArrayElementType(from: type) {
        guard let documentedType = arrayElementType as? any TypeStructureProvider.Type else {
            return nil
        }
        return documentedType.typeStructure
    }

    guard let documentedType = type as? any TypeStructureProvider.Type else {
        return nil
    }
    return documentedType.typeStructure
}

public func collectRelatedTypes(for type: Any.Type) -> [String: String]? {
    let targetType: Any.Type
    if let arrayElementType = extractArrayElementType(from: type) {
        targetType = arrayElementType
    } else {
        targetType = type
    }

    guard let documentedType = targetType as? any TypeStructureProvider.Type else {
        return nil
    }

    _ = documentedType.typeStructure
    _ = documentedType.relatedTypeNames

    var relatedTypes: [String: String] = [:]
    var typesToProcess: [String] = documentedType.relatedTypeNames
    var processedTypes: Set<String> = []

    var allNestedTypeNames = Set<String>(typesToProcess)
    func collectAllNestedTypeNames(from typeNames: [String]) {
        for typeName in typeNames {
            if allNestedTypeNames.contains(typeName) {
                continue
            }
            allNestedTypeNames.insert(typeName)

            if let nestedType = TypeRegistry.shared.type(forName: typeName) {
                _ = nestedType.typeStructure
                collectAllNestedTypeNames(from: nestedType.relatedTypeNames)
            }
        }
    }

    collectAllNestedTypeNames(from: typesToProcess)
    typesToProcess = Array(allNestedTypeNames)

    while !typesToProcess.isEmpty {
        let typeName = typesToProcess.removeFirst()

        if processedTypes.contains(typeName) {
            continue
        }
        processedTypes.insert(typeName)

        if let nestedType = TypeRegistry.shared.type(forName: typeName) {
            _ = nestedType.typeStructure
            _ = nestedType.relatedTypeNames

            relatedTypes[typeName] = nestedType.typeStructure

            typesToProcess.append(contentsOf: nestedType.relatedTypeNames)
        }
    }

    return relatedTypes.isEmpty ? nil : relatedTypes
}

private func extractArrayElementType(from type: Any.Type) -> Any.Type? {
    let typeName = String(describing: type)

    if typeName.hasPrefix("Array<"), typeName.hasSuffix(">") {
        let elementTypeName = String(typeName.dropFirst(6).dropLast())
        if let elementType = TypeRegistry.shared.type(forName: elementTypeName) {
            return elementType
        }
    }

    return nil
}

public func resolveRelatedTypes(for type: Any.Type) -> [String: String]? {
    guard let documentedType = type as? any TypeStructureProvider.Type else {
        return nil
    }

    let typeNames = documentedType.relatedTypeNames
    if typeNames.isEmpty {
        return nil
    }

    return [:]
}

private func extractNestedTypeNames(from structure: String) -> Set<String> {
    var typeNames: Set<String> = []

    let pattern = #"let\s+\w+:\s+([\w\[\]<>:,\s\?]+)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return typeNames
    }

    let nsString = structure as NSString
    let matches = regex.matches(in: structure, range: NSRange(location: 0, length: nsString.length))

    for match in matches {
        guard let range = Range(match.range(at: 1), in: structure) else { continue }
        let typeString = String(structure[range]).trimmingCharacters(in: .whitespaces)

        let typeWithoutOptional = typeString.hasSuffix("?") ? String(typeString.dropLast()) : typeString

        let baseType: String
        if typeWithoutOptional.hasPrefix("[") && typeWithoutOptional.hasSuffix("]") {
            baseType = String(typeWithoutOptional.dropFirst().dropLast())
        } else {
            baseType = typeWithoutOptional
        }

        if !isPrimitiveType(baseType) {
            typeNames.insert(baseType)
        }
    }

    return typeNames
}

private func isPrimitiveType(_ type: String) -> Bool {
    let primitives = ["Int", "String", "Double", "Bool", "Float", "Int64", "Int32", "UInt", "Date", "Data", "URL"]
    return primitives.contains(type)
}

public func generateStructureFromJSON(_ json: String) -> String? {
    guard let data = json.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        return nil
    }

    var lines = ["struct RequestBody {"]

    for (key, value) in jsonObject.sorted(by: { $0.key < $1.key }) {
        let type = inferType(from: value)
        lines.append("    let \(key): \(type)")
    }

    lines.append("}")
    return lines.joined(separator: "\n")
}

private func inferType(from value: Any) -> String {
    switch value {
    case is String:
        return "String"
    case is Int:
        return "Int"
    case is Double, is Float:
        return "Double"
    case is Bool:
        return "Bool"
    case let array as [Any]:
        if let first = array.first {
            let elementType = inferType(from: first)
            return "[\(elementType)]"
        }
        return "[Any]"
    case is [String: Any]:
        return "[String: Any]"
    case is NSNull:
        return "Any?"
    default:
        return "Any"
    }
}

public protocol TypeStructureProvider {
    static var typeStructure: String { get }
    static var relatedTypeNames: [String] { get }
}
