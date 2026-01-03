//
//  RequestBodyField.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public struct RequestBodyField: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: FieldType
    public let isRequired: Bool
    public let exampleValue: String?

    public init(
        id: String? = nil,
        name: String,
        type: FieldType,
        isRequired: Bool = true,
        exampleValue: String? = nil
    ) {
        self.id = id ?? name
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.exampleValue = exampleValue
    }

    public enum FieldType: Sendable, Hashable {
        case string
        case int
        case double
        case bool
        case array
        case object
        case unknown

        public var displayName: String {
            switch self {
            case .string: return "String"
            case .int: return "Int"
            case .double: return "Double"
            case .bool: return "Bool"
            case .array: return "Array"
            case .object: return "Object"
            case .unknown: return "Unknown"
            }
        }
    }
}

public enum RequestBodyParser {
    public static func parseFields(from jsonString: String) -> [RequestBodyField] {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return []
        }

        return jsonObject.map { key, value in
            let fieldType = detectType(from: value)
            let exampleValue = stringValue(from: value)

            return RequestBodyField(
                name: key,
                type: fieldType,
                isRequired: true,
                exampleValue: exampleValue
            )
        }.sorted { $0.name < $1.name }
    }

    private static func detectType(from value: Any) -> RequestBodyField.FieldType {
        switch value {
        case is String:
            return .string
        case is Int:
            return .int
        case is Double, is Float:
            return .double
        case is Bool:
            return .bool
        case is [Any]:
            return .array
        case is [String: Any]:
            return .object
        default:
            return .unknown
        }
    }

    private static func stringValue(from value: Any) -> String {
        switch value {
        case let str as String:
            return str
        case let num as NSNumber:
            return num.stringValue
        case let array as [Any]:
            return "[\(array.count) items]"
        case let dict as [String: Any]:
            return "{\(dict.count) fields}"
        default:
            return "\(value)"
        }
    }

    public static func buildJSON(from fields: [String: String], fieldTypes: [String: RequestBodyField.FieldType]) -> String? {
        var jsonDict: [String: Any] = [:]

        for (key, value) in fields {
            guard !value.isEmpty else { continue }

            let fieldType = fieldTypes[key] ?? .string

            switch fieldType {
            case .string:
                jsonDict[key] = value
            case .int:
                jsonDict[key] = Int(value) ?? 0
            case .double:
                jsonDict[key] = Double(value) ?? 0.0
            case .bool:
                jsonDict[key] = Bool(value) ?? false
            case .array, .object, .unknown:
                jsonDict[key] = value
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return jsonString
    }
}
