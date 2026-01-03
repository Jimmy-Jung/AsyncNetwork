//
//  EndpointMetadata.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// API 엔드포인트의 문서화 메타데이터
public struct EndpointMetadata: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let method: String
    public let path: String
    public let baseURLString: String
    public let headers: [String: String]?
    public let tags: [String]
    public let parameters: [ParameterInfo]
    public let requestBodyExample: String?
    public let requestBodyStructure: String?
    public let requestBodyRelatedTypes: [String: String]?
    public let responseStructure: String?
    public let responseExample: String?
    public let responseTypeName: String
    public let relatedTypes: [String: String]?

    public init(
        id: String,
        title: String,
        description: String,
        method: String,
        path: String,
        baseURLString: String,
        headers: [String: String]? = nil,
        tags: [String] = [],
        parameters: [ParameterInfo] = [],
        requestBodyExample: String? = nil,
        requestBodyStructure: String? = nil,
        requestBodyRelatedTypes: [String: String]? = nil,
        responseStructure: String? = nil,
        responseExample: String? = nil,
        responseTypeName: String,
        relatedTypes: [String: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.method = method
        self.path = path
        self.baseURLString = baseURLString
        self.headers = headers
        self.tags = tags
        self.parameters = parameters
        self.requestBodyExample = requestBodyExample
        self.requestBodyStructure = requestBodyStructure
        self.requestBodyRelatedTypes = requestBodyRelatedTypes
        self.responseStructure = responseStructure
        self.responseExample = responseExample
        self.responseTypeName = responseTypeName
        self.relatedTypes = relatedTypes
    }

    public var requestBodyFields: [RequestBodyFieldInfo] {
        if let structureText = requestBodyStructure {
            return extractFieldsFromStructure(structureText, relatedTypes: requestBodyRelatedTypes, example: requestBodyExample)
        }
        return []
    }

    private func extractFieldsFromStructure(
        _ structureText: String,
        relatedTypes: [String: String]?,
        example: String?,
        prefix: String = ""
    ) -> [RequestBodyFieldInfo] {
        var fields: [RequestBodyFieldInfo] = []
        let lines = structureText.split(separator: "\n").map { String($0) }
        var insideStruct = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("struct "), trimmed.contains("{") {
                insideStruct = true
                continue
            }

            if trimmed == "}" {
                insideStruct = false
                continue
            }

            if insideStruct, trimmed.hasPrefix("let ") || trimmed.hasPrefix("var ") {
                let components = trimmed.split(separator: ":").map { String($0) }
                guard components.count >= 2 else { continue }

                let nameComponent = components[0]
                    .replacingOccurrences(of: "let ", with: "")
                    .replacingOccurrences(of: "var ", with: "")
                    .trimmingCharacters(in: .whitespaces)

                let typeComponent = components[1].trimmingCharacters(in: .whitespaces)
                let isOptional = typeComponent.contains("?")
                let cleanType = typeComponent.replacingOccurrences(of: "?", with: "")

                let fieldKind: RequestBodyFieldInfo.FieldKind
                if cleanType.hasPrefix("["), cleanType.hasSuffix("]") {
                    fieldKind = .array
                } else if isPrimitiveType(cleanType) {
                    fieldKind = .primitive
                } else {
                    fieldKind = .object
                }

                let fieldName = prefix.isEmpty ? nameComponent : "\(prefix).\(nameComponent)"

                var exampleValue: String?
                if let example = example,
                   let data = example.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let value = json[nameComponent]
                {
                    exampleValue = "\(value)"
                }

                fields.append(RequestBodyFieldInfo(
                    name: fieldName,
                    type: cleanType,
                    isRequired: !isOptional,
                    exampleValue: exampleValue,
                    fieldKind: fieldKind
                ))

                let nestedTypeName: String?
                if cleanType.hasPrefix("["), cleanType.hasSuffix("]") {
                    let startIndex = cleanType.index(after: cleanType.startIndex)
                    let endIndex = cleanType.index(before: cleanType.endIndex)
                    nestedTypeName = String(cleanType[startIndex ..< endIndex])
                } else if !isPrimitiveType(cleanType) {
                    nestedTypeName = cleanType
                } else {
                    nestedTypeName = nil
                }

                if let typeName = nestedTypeName,
                   let relatedTypes = relatedTypes,
                   let nestedStructure = relatedTypes[typeName]
                {
                    let nestedFields = extractFieldsFromStructure(
                        nestedStructure,
                        relatedTypes: relatedTypes,
                        example: nil,
                        prefix: fieldName
                    )
                    fields.append(contentsOf: nestedFields)
                }
            }
        }

        return fields
    }

    private func isPrimitiveType(_ type: String) -> Bool {
        let primitiveTypes = [
            "String", "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Double", "Float", "Bool", "Date", "UUID", "URL"
        ]
        return primitiveTypes.contains(type)
    }
}

public struct ParameterInfo: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: String
    public let location: ParameterLocation
    public let isRequired: Bool
    public let description: String?
    public let defaultValue: String?
    public let exampleValue: String?

    public init(
        id: String,
        name: String,
        type: String,
        location: ParameterLocation,
        isRequired: Bool = false,
        description: String? = nil,
        defaultValue: String? = nil,
        exampleValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.location = location
        self.isRequired = isRequired
        self.description = description
        self.defaultValue = defaultValue
        self.exampleValue = exampleValue
    }
}

public enum ParameterLocation: String, Sendable, Hashable {
    case query
    case path
    case header
    case body
}

public struct RequestBodyFieldInfo: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: String
    public let isRequired: Bool
    public let exampleValue: String?
    public let fieldKind: FieldKind

    public enum FieldKind: String, Sendable, Hashable {
        case primitive // String, Int, Double, Bool 등
        case array // [OrderItemInput] 등
        case object // ShippingAddress, PaymentMethod 등
    }

    public init(
        id: String? = nil,
        name: String,
        type: String,
        isRequired: Bool = true,
        exampleValue: String? = nil,
        fieldKind: FieldKind = .primitive
    ) {
        self.id = id ?? name
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.exampleValue = exampleValue
        self.fieldKind = fieldKind
    }
}
