//
//  ArgumentParser.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/02.
//

import Foundation
import SwiftSyntax

// MARK: - Helper Types

struct MacroArguments {
    let responseType: String
    let title: String
    let description: String
    let baseURL: String?
    let isBaseURLLiteral: Bool // baseURL이 문자열 리터럴인지 여부
    let path: String
    let method: String
    let headers: [String: String]
    let tags: [String]
    let requestBodyExample: String?
    let responseExample: String?
}

struct PropertyWrapperInfo {
    let name: String
    let type: String
    let wrapperType: String
    let isRequired: Bool
    let headerKey: String? // HeaderField, CustomHeader용
    let defaultValue: String? // 기본값
}

struct ParsedRequestBodyField {
    let name: String
    let type: String
    let isRequired: Bool
    let exampleValue: String?
}

// MARK: - Argument Parsing

// swiftlint:disable:next function_body_length cyclomatic_complexity
func parseArguments(_ arguments: LabeledExprListSyntax) throws -> MacroArguments {
    var responseType: String?
    var title: String?
    var description = ""
    var baseURL: String?
    var isBaseURLLiteral = false
    var path: String?
    var method: String?
    var headers: [String: String] = [:]
    var tags: [String] = []
    var requestBodyExample: String?
    var responseExample: String?

    for argument in arguments {
        let label = argument.label?.text ?? ""
        let expr = argument.expression

        switch label {
        case "response":
            responseType = extractTypeName(from: expr)
        case "title":
            title = extractStringLiteral(from: expr)
        case "description":
            description = extractStringLiteral(from: expr) ?? ""
        case "baseURL":
            // 문자열 리터럴인지 확인
            if let literal = extractStringLiteral(from: expr) {
                baseURL = literal
                isBaseURLLiteral = true
            } else if let expression = extractExpression(from: expr) {
                baseURL = expression
                isBaseURLLiteral = false
            }
        case "path":
            path = extractStringLiteral(from: expr)
        case "method":
            method = extractStringOrEnumCase(from: expr)
        case "headers":
            headers = extractDictionary(from: expr)
        case "tags":
            tags = extractArray(from: expr)
        case "requestBodyExample":
            requestBodyExample = extractStringLiteral(from: expr)
        case "responseExample":
            responseExample = extractStringLiteral(from: expr)
        default:
            break
        }
    }

    guard let responseType = responseType else {
        throw APIRequestMacroError.missingRequiredArgument("response")
    }
    guard let title = title else {
        throw APIRequestMacroError.missingRequiredArgument("title")
    }
    guard let path = path else {
        throw APIRequestMacroError.missingRequiredArgument("path")
    }
    guard let method = method else {
        throw APIRequestMacroError.missingRequiredArgument("method")
    }

    return MacroArguments(
        responseType: responseType,
        title: title,
        description: description,
        baseURL: baseURL,
        isBaseURLLiteral: isBaseURLLiteral,
        path: path,
        method: method,
        headers: headers,
        tags: tags,
        requestBodyExample: requestBodyExample,
        responseExample: responseExample
    )
}

func extractTypeName(from expr: ExprSyntax) -> String? {
    if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
        // [Post].self → "[Post]"
        return memberAccess.base?.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return nil
}

func extractStringLiteral(from expr: ExprSyntax) -> String? {
    if let stringLiteral = expr.as(StringLiteralExprSyntax.self) {
        // Multi-line string literal의 모든 세그먼트를 결합
        var result = ""
        for segment in stringLiteral.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result += stringSegment.content.text
            }
        }
        return result.isEmpty ? nil : result
    }
    return nil
}

func extractExpression(from expr: ExprSyntax) -> String? {
    // 표현식 전체를 문자열로 반환 (APIConfiguration.jsonPlaceholder 등)
    return expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
}

func extractEnumCase(from expr: ExprSyntax) -> String? {
    if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
        return memberAccess.declName.baseName.text
    }
    return nil
}

func extractStringOrEnumCase(from expr: ExprSyntax) -> String? {
    // String 리터럴 시도
    if let stringValue = extractStringLiteral(from: expr) {
        return stringValue
    }
    // Enum case 시도 (.get → "get")
    if let enumValue = extractEnumCase(from: expr) {
        return enumValue
    }
    return nil
}

func extractDictionary(from expr: ExprSyntax) -> [String: String] {
    guard let dictionaryExpr = expr.as(DictionaryExprSyntax.self) else {
        return [:]
    }

    var result: [String: String] = [:]

    for element in dictionaryExpr.content.as(DictionaryElementListSyntax.self) ?? [] {
        guard let keyString = extractStringLiteral(from: element.key),
              let valueString = extractStringLiteral(from: element.value)
        else {
            continue
        }
        result[keyString] = valueString
    }

    return result
}

func extractArray(from expr: ExprSyntax) -> [String] {
    guard let arrayExpr = expr.as(ArrayExprSyntax.self) else {
        return []
    }

    var result: [String] = []

    for element in arrayExpr.elements {
        if let stringValue = extractStringLiteral(from: element.expression) {
            result.append(stringValue)
        }
    }

    return result
}

// MARK: - Request Body Field Parsing

/// requestBodyExample JSON 문자열에서 필드 정보를 파싱합니다
func parseRequestBodyFields(from jsonString: String) -> [ParsedRequestBodyField] {
    guard let data = jsonString.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        return []
    }

    return flattenFields(from: jsonObject, prefix: "").sorted { $0.name < $1.name }
}

/// 중첩된 객체를 평면화하여 필드 목록 생성
private func flattenFields(from dictionary: [String: Any], prefix: String) -> [ParsedRequestBodyField] {
    var fields: [ParsedRequestBodyField] = []

    for (key, value) in dictionary {
        let fieldName = prefix.isEmpty ? key : "\(prefix).\(key)"

        switch value {
        case let dict as [String: Any]:
            // 중첩된 객체는 재귀적으로 평면화
            fields.append(contentsOf: flattenFields(from: dict, prefix: fieldName))
        case let array as [Any]:
            // 배열의 경우
            if let firstElement = array.first as? [String: Any] {
                // 배열의 첫 번째 요소가 객체면 그 구조를 사용
                let arrayFields = flattenFields(from: firstElement, prefix: "\(fieldName)[0]")
                fields.append(contentsOf: arrayFields)
            } else {
                // 기본 타입 배열
                let fieldType = detectArrayElementType(from: array)
                let exampleValue = formatArrayExample(from: array)
                fields.append(ParsedRequestBodyField(
                    name: fieldName,
                    type: "[\(fieldType)]",
                    isRequired: true,
                    exampleValue: exampleValue
                ))
            }
        default:
            // 기본 타입
            let fieldType = detectFieldType(from: value)
            let exampleValue = stringValue(from: value)
            fields.append(ParsedRequestBodyField(
                name: fieldName,
                type: fieldType,
                isRequired: true,
                exampleValue: exampleValue
            ))
        }
    }

    return fields
}

/// 배열 요소의 타입 감지
private func detectArrayElementType(from array: [Any]) -> String {
    guard let first = array.first else { return "Any" }
    return detectFieldType(from: first)
}

/// 배열 예시값 포맷팅
private func formatArrayExample(from array: [Any]) -> String {
    if array.isEmpty { return "[]" }
    if array.count <= 2 {
        let values = array.map { stringValue(from: $0) }
        return "[\(values.joined(separator: ", "))]"
    }
    return "[\(array.count) items]"
}

/// 값의 타입 감지
private func detectFieldType(from value: Any) -> String {
    switch value {
    case is String:
        return "String"
    case is Int:
        return "Int"
    case is Double, is Float:
        return "Double"
    case is Bool:
        return "Bool"
    case is [Any]:
        return "Array"
    case is [String: Any]:
        return "Object"
    default:
        return "Unknown"
    }
}

/// 값을 문자열로 변환
private func stringValue(from value: Any) -> String {
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
