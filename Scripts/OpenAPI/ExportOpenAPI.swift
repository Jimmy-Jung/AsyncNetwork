#!/usr/bin/env swift
//
//  ExportOpenAPI.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/05.
//
//  @APIRequest와 Property Wrappers를 파싱하여 OpenAPI 3.0 스펙 생성
//

import Foundation

// MARK: - 출력 헬퍼

func printInfo(_ message: String) {
    print("ℹ️  \(message)")
}

func printSuccess(_ message: String) {
    print("✅ \(message)")
}

func printError(_ message: String) {
    print("❌ \(message)")
}

func printWarning(_ message: String) {
    print("⚠️  \(message)")
}

// MARK: - Models

struct APIRequestInfo: Codable {
    let name: String
    let response: String
    let title: String
    let description: String
    let baseURL: String
    let path: String
    let method: String
    let tags: [String]
    let responseExample: String?
    let requestBodyExample: String?
    let properties: [PropertyInfo]
    let errorResponses: [String: String] // [statusCode: TypeName]
}

struct PropertyInfo: Codable {
    let name: String
    let type: String
    let wrapper: String // "path", "query", "header", "customHeader", "body"
    let isOptional: Bool
    let customKey: String?
    let defaultValue: String?
}

struct TypeInfo: Codable {
    let name: String
    let properties: [TypeProperty]
    let isEnum: Bool
}

struct TypeProperty: Codable {
    let name: String
    let type: String
    let isOptional: Bool
}

// MARK: - 간단한 OpenAPI 생성

func generateSimpleOpenAPI(
    requests: [APIRequestInfo],
    dtos: [DTOInfo],
    scemers: [SemerInfo],
    title: String,
    version: String,
    description: String?,
    format: String
) -> String {
    if format == "json" {
        return generateJSON(requests: requests, dtos: dtos, scemers: scemers, title: title, version: version, description: description)
    } else {
        return generateYAML(requests: requests, dtos: dtos, title: title, version: version, description: description)
    }
}

func generateJSON(requests: [APIRequestInfo], dtos: [DTOInfo], scemers: [SemerInfo], title: String, version: String, description: String?) -> String {
    var json = """
    {
      "openapi": "3.0.0",
      "info": {
        "title": "\(title)",
        "version": "\(version)"
    """

    if let desc = description {
        json += ",\n"
        json += """
                "description": "\(desc.replacingOccurrences(of: "\"", with: "\\\""))"
        """
    }

    // baseURL 수집 및 변환
    let baseURLMap = extractBaseURLs(from: requests)
    let uniqueBaseURLs = Array(Set(requests.map { resolveBaseURL($0.baseURL, map: baseURLMap) })).sorted()

    json += """

      },
      "servers": [
    """

    for (index, baseURL) in uniqueBaseURLs.enumerated() {
        if index > 0 {
            json += ","
        }
        json += """
            
                {
                  "url": "\(baseURL)",
                  "description": "API Server"
                }
        """
    }

    json += """

      ],
      "paths": {
    """

    // Path별로 그룹화하여 병합
    let groupedByPath = Dictionary(grouping: requests, by: { $0.path })
    let sortedPaths = groupedByPath.keys.sorted()

    for (pathIndex, path) in sortedPaths.enumerated() {
        if pathIndex > 0 {
            json += ","
        }
        let pathRequests = groupedByPath[path]!
        json += generateMergedPathItem(path: path, requests: pathRequests, baseURLMap: baseURLMap, scemers: scemers, dtos: dtos)
    }

    json += """
        
          },
          "components": {
            "schemas": {
    """

    // DTO 스키마 생성
    for (index, dto) in dtos.enumerated() {
        if index > 0 {
            json += ","
        }
        let schema = jsonToSchema(dto.fixtureJSON)
        json += """

              "\(dto.name)": \(schema)
        """
    }

    json += """

        }
      }
    }
    """

    return json
}

// baseURL 변수를 실제 URL로 변환
func extractBaseURLs(from _: [APIRequestInfo]) -> [String: String] {
    var map: [String: String] = [:]

    // 알려진 패턴 매핑
    map["jsonPlaceholderURL"] = "https://jsonplaceholder.typicode.com"
    map["apiExampleURL"] = "https://api.example.com"

    return map
}

func resolveBaseURL(_ varName: String, map: [String: String]) -> String {
    return map[varName] ?? varName
}

// 타입 스키마 생성
func generateTypeSchema(type: TypeInfo) -> String {
    var json = """
        
              "\(type.name)": {
                "type": "object",
                "properties": {
    """

    for (index, prop) in type.properties.enumerated() {
        if index > 0 {
            json += ","
        }

        let openAPIType = swiftTypeToOpenAPIType(prop.type)

        // $ref가 있으면 type 대신 $ref 사용
        if let ref = openAPIType.ref {
            json += """
                
                          "\(prop.name)": {
                            "$ref": "#/components/schemas/\(ref)"
                          }
            """
        } else {
            json += """
                
                          "\(prop.name)": {
                            "type": "\(openAPIType.type)"
            """

            if let format = openAPIType.format {
                json += ",\n"
                json += """
                                "format": "\(format)"
                """
            }

            if let items = openAPIType.items {
                json += ",\n"
                json += """
                                "items": {
                                  "type": "\(items)"
                                }
                """
            }

            json += """
                
                          }
            """
        }
    }

    json += """
        
                }
    """

    // Required 필드 추가
    let requiredFields = type.properties.filter { !$0.isOptional }.map { $0.name }
    if !requiredFields.isEmpty {
        json += ",\n"
        json += """
                    "required": [\(requiredFields.map { "\"\($0)\"" }.joined(separator: ", "))]
        """
    }

    json += """
        
              }
    """

    return json
}

// Swift 타입을 OpenAPI 타입으로 변환
struct OpenAPIType {
    let type: String
    let format: String?
    let items: String?
    let ref: String?
}

func swiftTypeToOpenAPIType(_ type: String) -> OpenAPIType {
    // Optional 제거
    let cleanType = type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)

    // 배열 처리
    if cleanType.hasPrefix("[") && cleanType.hasSuffix("]") {
        let itemType = String(cleanType.dropFirst().dropLast())
        let itemOpenAPIType = swiftTypeToOpenAPIType(itemType)
        return OpenAPIType(type: "array", format: nil, items: itemOpenAPIType.type, ref: itemOpenAPIType.ref)
    }

    // 기본 타입 매핑
    switch cleanType {
    case "String":
        return OpenAPIType(type: "string", format: nil, items: nil, ref: nil)
    case "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
        return OpenAPIType(type: "integer", format: "int64", items: nil, ref: nil)
    case "Double", "Float", "CGFloat":
        return OpenAPIType(type: "number", format: "double", items: nil, ref: nil)
    case "Bool":
        return OpenAPIType(type: "boolean", format: nil, items: nil, ref: nil)
    case "Date":
        return OpenAPIType(type: "string", format: "date-time", items: nil, ref: nil)
    case "UUID":
        return OpenAPIType(type: "string", format: "uuid", items: nil, ref: nil)
    case "URL":
        return OpenAPIType(type: "string", format: "uri", items: nil, ref: nil)
    default:
        // 커스텀 타입은 $ref로 참조
        return OpenAPIType(type: "object", format: nil, items: nil, ref: cleanType)
    }
}

// Path별로 병합된 Operation 생성
func generateMergedPathItem(path: String, requests: [APIRequestInfo], baseURLMap: [String: String], scemers: [SemerInfo], dtos: [DTOInfo]) -> String {
    var json = """
        
            "\(path)": {
    """

    for (index, request) in requests.enumerated() {
        if index > 0 {
            json += ","
        }
        json += generateOperation(request: request, baseURLMap: baseURLMap, scemers: scemers, dtos: dtos)
    }

    json += """
        
            }
    """

    return json
}

// 단일 Operation 생성
func generateOperation(request: APIRequestInfo, baseURLMap _: [String: String], scemers: [SemerInfo], dtos: [DTOInfo]) -> String {
    let parameters = request.properties.filter { ["path", "query", "header", "customHeader"].contains($0.wrapper) }
    let bodyProp = request.properties.first { $0.wrapper == "body" }

    var json = """
        
              "\(request.method)": {
                "summary": "\(request.title)",
                "description": "\(request.description.replacingOccurrences(of: "\"", with: "\\\""))",
                "tags": [\(request.tags.map { "\"\($0)\"" }.joined(separator: ", "))]
    """

    // Parameters
    if !parameters.isEmpty {
        json += ",\n"
        json += """
                    "parameters": [
        """
        for (index, param) in parameters.enumerated() {
            if index > 0 {
                json += ","
            }
            json += generateParameter(param: param)
        }
        json += """
            
                    ]
        """
    }

    // Request Body - $ref 사용
    if let body = bodyProp {
        json += ",\n"
        let cleanType = body.type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)
        json += """
                    "requestBody": {
                      "required": \(!body.isOptional),
                      "content": {
                        "application/json": {
                          "schema": {
                            "$ref": "#/components/schemas/\(cleanType)"
                          }
        """

        if let example = request.requestBodyExample {
            json += ",\n"
            json += """
                              "example": \(example)
            """
        }

        json += """
            
                        }
                      }
                    }
        """
    }

    // Responses - $ref 사용
    json += ",\n"
    let responseType = request.response
    let isArray = responseType.hasPrefix("[")
    let cleanResponseType = responseType
        .replacingOccurrences(of: "[", with: "")
        .replacingOccurrences(of: "]", with: "")
        .trimmingCharacters(in: .whitespaces)

    json += """
                "responses": {
                  "200": {
                    "description": "Success",
                    "content": {
                      "application/json": {
                        "schema": {
    """

    if isArray {
        json += """
            
                              "type": "array",
                              "items": {
                                "$ref": "#/components/schemas/\(cleanResponseType)"
                              }
        """
    } else {
        json += """
            
                              "$ref": "#/components/schemas/\(cleanResponseType)"
        """
    }

    json += """
        
                        }
    """

    if let example = request.responseExample {
        json += ",\n"
        json += """
                            "example": \(example)
        """
    }

    json += """
        
                      }
                    }
                  }
    """

    // Error responses from @APIRequest errorResponses parameter
    for (statusCode, typeName) in request.errorResponses.sorted(by: { $0.key < $1.key }) {
        json += """
        ,
                          "\(statusCode)": {
                            "description": "Error",
                            "content": {
                              "application/json": {
                                "schema": {
                                  "$ref": "#/components/schemas/\(typeName)"
                                }
        """

        // DTO에서 example 찾기
        if let dto = dtos.first(where: { $0.name == typeName }) {
            json += """
            ,
                                    "example": \(dto.fixtureJSON)
            """
        }

        json += """

                              }
                            }
                          }
        """
    }

    // Error responses from @TestableSchemer (errorResponses가 없는 경우에만)
    if request.errorResponses.isEmpty, let semer = scemers.first(where: { $0.requestName == request.name }) {
        for errorExample in semer.errorExamples {
            json += """
            ,
                              "\(errorExample.statusCode)": {
                                "description": "Error",
                                "content": {
                                  "application/json": {
            """

            // JSON을 파싱하여 schema 생성
            if let data = errorExample.json.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                json += """

                                        "schema": {
                                          "type": "object",
                                          "properties": {
                """

                let sortedKeys = jsonObject.keys.sorted()
                for (index, key) in sortedKeys.enumerated() {
                    if index > 0 {
                        json += ","
                    }

                    let value = jsonObject[key]!
                    let type: String
                    let format: String?

                    switch value {
                    case is String:
                        type = "string"
                        format = nil
                    case is Int:
                        type = "integer"
                        format = "int64"
                    case is Double, is Float:
                        type = "number"
                        format = "double"
                    case is Bool:
                        type = "boolean"
                        format = nil
                    default:
                        type = "string"
                        format = nil
                    }

                    json += """

                                                "\(key)": {
                                                  "type": "\(type)"
                    """

                    if let fmt = format {
                        json += """
                        ,
                                                      "format": "\(fmt)"
                        """
                    }

                    json += """

                                                }
                    """
                }

                json += """

                                          }
                                        },
                """
            }

            json += """

                                    "example": \(errorExample.json)
                                  }
                                }
                              }
            """
        }
    }

    json += """

                }
              }
    """

    return json
}

func generatePathItem(request: APIRequestInfo, format _: String) -> String {
    let parameters = request.properties.filter { ["path", "query", "header", "customHeader"].contains($0.wrapper) }
    let bodyProp = request.properties.first { $0.wrapper == "body" }

    var json = """

        "\(request.path)": {
          "\(request.method)": {
            "summary": "\(request.title)",
            "description": "\(request.description.replacingOccurrences(of: "\"", with: "\\\""))",
            "tags": [\(request.tags.map { "\"\($0)\"" }.joined(separator: ", "))]
    """

    // Parameters
    if !parameters.isEmpty {
        json += ",\n"
        json += """
                    "parameters": [
        """
        for (index, param) in parameters.enumerated() {
            if index > 0 {
                json += ","
            }
            json += generateParameter(param: param)
        }
        json += """

                ]
        """
    }

    // Request Body
    if let body = bodyProp {
        json += ",\n"
        json += """
            "requestBody": {
              "required": true,
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "data": {
                        "type": "object",
                        "description": "Request body of type \(body.type)"
                      }
                    }
                  }
        """

        if let example = request.requestBodyExample {
            json += ",\n"
            json += """
                              "example": \(example)
            """
        }

        json += """

                    }
                  }
                }
        """
    }

    // Responses
    json += ",\n"
    json += """
            "responses": {
              "200": {
                "description": "Success",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "\(request.response.hasPrefix("[") ? "array" : "object")",
                      "description": "Response of type \(request.response)"
                    }
    """

    if let example = request.responseExample {
        json += ",\n"
        json += """
                            "example": \(example)
        """
    }

    json += """

                  }
                }
              }
            }
          }
        }
    """

    return json
}

func generateParameter(param: PropertyInfo) -> String {
    let location = param.wrapper == "path" ? "path" : (param.wrapper == "query" ? "query" : "header")

    // CustomHeader는 customKey에 실제 헤더 이름이 있음
    // HeaderField의 enum은 변환 필요
    var paramName = param.customKey ?? param.name

    // HeaderField enum 변환
    if param.wrapper == "header" && param.customKey == nil {
        paramName = convertHeaderFieldName(param.name)
    }

    let required = param.wrapper == "path" || !param.isOptional

    var schemaJson = """

                  "type": "\(swiftTypeToOpenAPI(param.type))"
    """

    // default 값 추가
    if let defaultValue = param.defaultValue {
        let cleanedDefault = cleanDefaultValue(defaultValue, type: param.type)
        schemaJson += ",\n"
        schemaJson += """
                  "default": \(cleanedDefault)
        """
    }

    return """

              {
                "name": "\(paramName)",
                "in": "\(location)",
                "required": \(required),
                "schema": {\(schemaJson)
                }
              }
    """
}

// HeaderField enum을 HTTP 헤더 이름으로 변환
func convertHeaderFieldName(_ name: String) -> String {
    let mapping: [String: String] = [
        "userAgent": "User-Agent",
        "contentType": "Content-Type",
        "acceptLanguage": "Accept-Language",
        "authorization": "Authorization",
        "requestId": "X-Request-ID",
        "sessionId": "X-Session-ID",
        "timestamp": "X-Timestamp",
    ]
    return mapping[name] ?? name
}

// Swift default 값을 OpenAPI JSON 형식으로 변환
func cleanDefaultValue(_ value: String, type: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespaces)

    // 문자열 타입인 경우
    if type.contains("String") {
        // 이미 따옴표로 감싸져 있으면 그대로 반환
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            return trimmed
        }
        // 그렇지 않으면 따옴표로 감싸기
        return "\"\(trimmed)\""
    }

    // 숫자 타입
    if type.contains("Int") || type.contains("Double") || type.contains("Float") {
        return trimmed
    }

    // Bool 타입
    if type.contains("Bool") {
        return trimmed.lowercased() // true/false
    }

    // 배열/딕셔너리 등 복잡한 타입
    if trimmed.hasPrefix("[") || trimmed.hasPrefix("{") {
        return trimmed
    }

    // 기본값: 문자열로 처리
    return "\"\(trimmed)\""
}

func swiftTypeToOpenAPI(_ type: String) -> String {
    if type.contains("Int") { return "integer" }
    if type.contains("Double") || type.contains("Float") { return "number" }
    if type.contains("Bool") { return "boolean" }
    return "string"
}

func generateYAML(requests: [APIRequestInfo], dtos _: [DTOInfo], title: String, version: String, description: String?) -> String {
    var yaml = """
    openapi: 3.0.0
    info:
      title: \(title)
      version: \(version)
    """

    if let desc = description {
        yaml += "\n  description: \(desc)"
    }

    // baseURL 수집
    let uniqueBaseURLs = Array(Set(requests.map { $0.baseURL })).sorted()

    yaml += """

    servers:
    """

    for baseURL in uniqueBaseURLs {
        yaml += """

          - url: \(baseURL)
            description: API Server
        """
    }

    yaml += """

    paths:
    """

    for request in requests {
        yaml += """

          \(request.path):
            \(request.method):
              summary: \(request.title)
              description: \(request.description)
              tags: [\(request.tags.joined(separator: ", "))]
              responses:
                '200':
                  description: Success
        """
    }

    yaml += """

    components:
      schemas: {}
    """

    return yaml
}

// MARK: - 파서 (간단 버전)

func parseAPIRequests(from paths: [String]) throws -> [APIRequestInfo] {
    var allRequests: [APIRequestInfo] = []
    var constantMap: [String: String] = [:]

    // 1단계: 모든 파일에서 상수 선언 수집
    for path in paths {
        let files = try findSwiftFiles(in: path)
        for file in files {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let constants = extractConstants(from: content)
            constantMap.merge(constants) { _, new in new }
        }
    }

    // 2단계: API 요청 파싱 (상수 맵 전달)
    for path in paths {
        let files = try findSwiftFiles(in: path)
        for file in files {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let requests = extractAPIRequests(from: content, constants: constantMap)
            allRequests.append(contentsOf: requests)
        }
    }

    return allRequests
}

// MARK: - DTO 파싱

func parseTestableDTOs(from paths: [String]) throws -> [DTOInfo] {
    var allDTOs: [DTOInfo] = []

    for path in paths {
        let files = try findSwiftFiles(in: path)
        for file in files {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let dtos = extractTestableDTOs(from: content)
            allDTOs.append(contentsOf: dtos)
        }
    }

    return allDTOs
}

func parseTestableScemers(from paths: [String]) throws -> [SemerInfo] {
    var allScemers: [SemerInfo] = []

    for path in paths {
        let files = try findSwiftFiles(in: path)
        for file in files {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let scemers = extractTestableScemers(from: content)
            allScemers.append(contentsOf: scemers)
        }
    }

    return allScemers
}

func parseDocumentedTypes(from paths: [String]) throws -> [TypeInfo] {
    var allTypes: [TypeInfo] = []

    for path in paths {
        let files = try findSwiftFiles(in: path)

        for file in files {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let types = extractDocumentedTypes(from: content)
            allTypes.append(contentsOf: types)
        }
    }

    return allTypes
}

func extractDocumentedTypes(from content: String) -> [TypeInfo] {
    var types: [TypeInfo] = []
    let lines = content.components(separatedBy: .newlines)

    var i = 0
    while i < lines.count {
        let line = lines[i]

        if line.trimmingCharacters(in: .whitespaces).hasPrefix("@DocumentedType") {
            // 다음 줄에서 struct/enum/class 찾기
            if i + 1 < lines.count {
                let nextLine = lines[i + 1]

                if let typeName = extractTypeName(from: nextLine) {
                    let properties = extractTypeProperties(from: lines, startingAt: i + 2)

                    types.append(TypeInfo(
                        name: typeName,
                        properties: properties,
                        isEnum: nextLine.contains("enum")
                    ))
                }
            }
        }

        i += 1
    }

    return types
}

func extractTypeName(from line: String) -> String? {
    // struct, class, enum 이름 추출
    let patterns = [
        #"struct\s+(\w+)"#,
        #"class\s+(\w+)"#,
        #"enum\s+(\w+)"#,
    ]

    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           let range = Range(match.range(at: 1), in: line)
        {
            return String(line[range])
        }
    }

    return nil
}

func extractTypeProperties(from lines: [String], startingAt start: Int) -> [TypeProperty] {
    var properties: [TypeProperty] = []
    var i = start
    var braceCount = 0
    var foundOpenBrace = false

    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 중괄호 카운팅
        for char in line {
            if char == "{" {
                foundOpenBrace = true
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if foundOpenBrace, braceCount == 0 {
                    return properties
                }
            }
        }

        // 다음 @DocumentedType 또는 @APIRequest 발견 시 중단
        if trimmed.hasPrefix("@DocumentedType") || trimmed.hasPrefix("@APIRequest") {
            break
        }

        // 프로퍼티 라인 파싱 (let, var)
        if let property = parseTypePropertyLine(line: trimmed) {
            properties.append(property)
        }

        i += 1
    }

    return properties
}

func parseTypePropertyLine(line: String) -> TypeProperty? {
    // let/var name: Type 패턴
    let pattern = #"(let|var)\s+(\w+):\s*([\w\[\]<>., ]+?)(\?)?(?:\s*=|$)"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))
    else {
        return nil
    }

    let name = extractMatch(from: line, match: match, at: 2) ?? ""
    let type = extractMatch(from: line, match: match, at: 3) ?? ""
    let isOptional = extractMatch(from: line, match: match, at: 4) != nil

    return TypeProperty(
        name: name,
        type: type.trimmingCharacters(in: .whitespaces),
        isOptional: isOptional
    )
}

func findSwiftFiles(in directory: String) throws -> [String] {
    let fileManager = FileManager.default
    var swiftFiles: [String] = []

    guard let enumerator = fileManager.enumerator(atPath: directory) else {
        throw NSError(domain: "Parser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot enumerate: \(directory)"])
    }

    while let file = enumerator.nextObject() as? String {
        if file.hasSuffix(".swift"), !file.contains("Generated") {
            swiftFiles.append("\(directory)/\(file)")
        }
    }

    return swiftFiles
}

// MARK: - DTO 정보 구조체

struct DTOInfo {
    let name: String
    let fixtureJSON: String
}

struct ErrorExample {
    let statusCode: String
    let json: String
}

struct SemerInfo {
    let requestName: String
    let errorExamples: [ErrorExample]
}

// MARK: - 상수 추출

/// Swift 파일에서 let 상수 선언을 추출합니다
func extractConstants(from content: String) -> [String: String] {
    var constants: [String: String] = [:]
    let lines = content.components(separatedBy: .newlines)

    // let constantName = "value" 패턴 찾기
    let pattern = #"^\s*let\s+(\w+)\s*=\s*"([^"]+)""#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return constants
    }

    for line in lines {
        let range = NSRange(line.startIndex..., in: line)
        if let match = regex.firstMatch(in: line, range: range),
           let nameRange = Range(match.range(at: 1), in: line),
           let valueRange = Range(match.range(at: 2), in: line)
        {
            let name = String(line[nameRange])
            let value = String(line[valueRange])
            constants[name] = value
        }
    }

    return constants
}

// MARK: - @Response/@TestableDTO 파싱

/// Swift 파일에서 @TestableDTO 또는 @Response를 파싱하여 DTO 정보를 추출합니다
func extractTestableDTOs(from content: String) -> [DTOInfo] {
    var dtos: [DTOInfo] = []
    let lines = content.components(separatedBy: .newlines)

    var i = 0
    while i < lines.count {
        let line = lines[i].trimmingCharacters(in: .whitespaces)

        // @TestableDTO 또는 @Response 찾기
        if line.hasPrefix("@TestableDTO") || line.hasPrefix("@Response") {
            // fixtureJSON 파라미터 추출
            var fixtureJSON = ""
            var inFixtureJSON = false
            var tripleQuoteCount = 0
            var jsonLines: [String] = []

            // @TestableDTO 블록 내에서 fixtureJSON 찾기
            var j = i
            while j < lines.count, j < i + 100 {
                let currentLine = lines[j]

                // fixtureJSON: """ 시작
                if currentLine.contains("fixtureJSON:"), currentLine.contains("\"\"\"") {
                    inFixtureJSON = true
                    tripleQuoteCount = 1
                    j += 1
                    continue
                }

                // JSON 내용 수집
                if inFixtureJSON {
                    // 종료 """ 찾기
                    if currentLine.contains("\"\"\"") {
                        tripleQuoteCount += 1
                        if tripleQuoteCount == 2 {
                            fixtureJSON = jsonLines.joined(separator: "\n")
                            break
                        }
                    } else {
                        jsonLines.append(currentLine)
                    }
                }

                j += 1
            }

            // struct 이름 찾기
            var structName = ""
            var k = i + 1
            while k < lines.count, k < i + 100 {
                let structLine = lines[k].trimmingCharacters(in: .whitespaces)
                if structLine.hasPrefix("struct ") {
                    // struct Name { 에서 Name 추출
                    let pattern = #"struct\s+(\w+)"#
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       let match = regex.firstMatch(in: structLine, range: NSRange(structLine.startIndex..., in: structLine)),
                       let range = Range(match.range(at: 1), in: structLine)
                    {
                        structName = String(structLine[range])
                        break
                    }
                }
                k += 1
            }

            // DTO 정보 저장
            if !structName.isEmpty, !fixtureJSON.isEmpty {
                dtos.append(DTOInfo(name: structName, fixtureJSON: fixtureJSON))
            }
        }

        i += 1
    }

    return dtos
}

/// JSON 문자열을 OpenAPI Schema로 변환
func jsonToSchema(_ json: String) -> String {
    guard let data = json.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        return """
        {
          "type": "object"
        }
        """
    }

    var properties: [String] = []
    var required: [String] = []

    for (key, value) in jsonObject.sorted(by: { $0.key < $1.key }) {
        required.append("\"\(key)\"")

        let type: String
        let format: String?

        switch value {
        case is String:
            type = "string"
            format = nil
        case is Int:
            type = "integer"
            format = "int64"
        case is Double, is Float:
            type = "number"
            format = "double"
        case is Bool:
            type = "boolean"
            format = nil
        case is [Any]:
            type = "array"
            format = nil
        case is [String: Any]:
            type = "object"
            format = nil
        default:
            type = "string"
            format = nil
        }

        var propertySchema = """
          "\(key)": {
            "type": "\(type)"
        """

        if let fmt = format {
            propertySchema += """
            ,
                        "format": "\(fmt)"
            """
        }

        propertySchema += """

          }
        """

        properties.append(propertySchema)
    }

    let schema = """
    {
      "type": "object",
      "properties": {
        \(properties.joined(separator: ",\n    "))
      },
      "required": [\(required.joined(separator: ", "))]
    }
    """

    return schema
}

// MARK: - @TestableSchemer 파싱

/// Swift 파일에서 @TestableSchemer를 파싱하여 에러 예시를 추출합니다
func extractTestableScemers(from content: String) -> [SemerInfo] {
    var scemers: [SemerInfo] = []
    let lines = content.components(separatedBy: .newlines)

    var i = 0
    while i < lines.count {
        let line = lines[i].trimmingCharacters(in: .whitespaces)

        // @TestableSchemer 찾기
        if line.hasPrefix("@TestableSchemer") {
            var errorExamples: [ErrorExample] = []

            // errorExamples 블록 찾기
            var j = i
            var inErrorExamples = false
            var blockContent = ""

            while j < lines.count, j < i + 100 {
                let currentLine = lines[j]
                blockContent += currentLine + "\n"

                if currentLine.contains("errorExamples:") {
                    inErrorExamples = true
                }

                // struct 발견 시 종료
                if currentLine.trimmingCharacters(in: .whitespaces).hasPrefix("struct ") {
                    break
                }

                j += 1
            }

            // blockContent에서 "404": """...""" 패턴 추출
            if inErrorExamples {
                let pattern = #""(\d{3})":\s*"""([^"]*(?:(?:"{1,2}(?!")[^"]*)*)*)""""#
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
                    let nsRange = NSRange(blockContent.startIndex..., in: blockContent)
                    let matches = regex.matches(in: blockContent, range: nsRange)

                    for match in matches {
                        if let statusRange = Range(match.range(at: 1), in: blockContent),
                           let jsonRange = Range(match.range(at: 2), in: blockContent)
                        {
                            let statusCode = String(blockContent[statusRange])
                            let json = String(blockContent[jsonRange])
                            errorExamples.append(ErrorExample(statusCode: statusCode, json: json))
                        }
                    }
                }
            }

            // struct 이름 찾기
            var structName = ""
            var k = i + 1
            while k < lines.count, k < i + 100 {
                let structLine = lines[k].trimmingCharacters(in: .whitespaces)
                if structLine.hasPrefix("struct ") {
                    let pattern = #"struct\s+(\w+)"#
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       let match = regex.firstMatch(in: structLine, range: NSRange(structLine.startIndex..., in: structLine)),
                       let range = Range(match.range(at: 1), in: structLine)
                    {
                        structName = String(structLine[range])
                        break
                    }
                }
                k += 1
            }

            // Semer 정보 저장
            if !structName.isEmpty, !errorExamples.isEmpty {
                scemers.append(SemerInfo(requestName: structName, errorExamples: errorExamples))
            }
        }

        i += 1
    }

    return scemers
}

// MARK: - API Request 파싱

func extractAPIRequests(from content: String, constants: [String: String] = [:]) -> [APIRequestInfo] {
    var requests: [APIRequestInfo] = []
    let lines = content.components(separatedBy: .newlines)

    var i = 0
    while i < lines.count {
        let line = lines[i]

        if line.trimmingCharacters(in: .whitespaces).hasPrefix("@APIRequest(") {
            // @APIRequest 블록 추출
            var block = ""
            var depth = 0
            var foundParen = false

            for j in i ..< lines.count {
                let currentLine = lines[j]
                block += currentLine + "\n"

                for char in currentLine {
                    if char == "(" { foundParen = true; depth += 1 }
                    else if char == ")" { depth -= 1; if foundParen, depth == 0 { break } }
                }

                if foundParen, depth == 0 {
                    i = j
                    break
                }
            }

            // struct 이름 (다른 매크로들을 건너뛰기)
            var structLineIndex = i + 1
            let maxLookAhead = 50 // 최대 50줄까지만 탐색
            while structLineIndex < lines.count, structLineIndex < i + maxLookAhead {
                let line = lines[structLineIndex].trimmingCharacters(in: .whitespaces)

                // struct를 찾았으면 처리
                if line.hasPrefix("struct ") {
                    if let name = extractStructName(from: lines[structLineIndex]) {
                        // properties 추출
                        let properties = extractProperties(from: lines, startingAt: structLineIndex + 1)

                        if let request = parseAPIRequestBlock(block: block, name: name, properties: properties, constants: constants) {
                            requests.append(request)
                        }
                    }
                    break
                }

                structLineIndex += 1
            }
        }

        i += 1
    }

    return requests
}

func extractStructName(from line: String) -> String? {
    let pattern = #"struct\s+(\w+)"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
          let range = Range(match.range(at: 1), in: line)
    else {
        return nil
    }
    return String(line[range])
}

func extractProperties(from lines: [String], startingAt start: Int) -> [PropertyInfo] {
    var properties: [PropertyInfo] = []
    var i = start
    var braceCount = 0
    var foundOpenBrace = false

    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 중괄호 카운팅
        for char in line {
            if char == "{" {
                foundOpenBrace = true
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if foundOpenBrace, braceCount == 0 {
                    // struct 블록 종료
                    return properties
                }
            }
        }

        // 빈 struct 처리: struct Name {}
        if !foundOpenBrace, trimmed == "}" {
            break
        }

        // 다음 @APIRequest 발견 시 중단
        if trimmed.hasPrefix("@APIRequest") {
            break
        }

        if trimmed.hasPrefix("@PathParameter") {
            if let prop = parsePropertyLine(line: line, wrapper: "path") {
                properties.append(prop)
            }
        } else if trimmed.hasPrefix("@QueryParameter") {
            if let prop = parsePropertyLine(line: line, wrapper: "query") {
                var finalProp = prop
                if let customKey = extractCustomKey(from: line) {
                    finalProp = PropertyInfo(name: prop.name, type: prop.type, wrapper: prop.wrapper,
                                             isOptional: prop.isOptional, customKey: customKey, defaultValue: prop.defaultValue)
                }
                properties.append(finalProp)
            }
        } else if trimmed.hasPrefix("@HeaderField") {
            if let prop = parsePropertyLine(line: line, wrapper: "header") {
                properties.append(prop)
            }
        } else if trimmed.hasPrefix("@CustomHeader") {
            if let prop = parsePropertyLine(line: line, wrapper: "customHeader") {
                var finalProp = prop
                // CustomHeader("X-Custom-Header")에서 헤더 이름 추출
                if let headerName = extractCustomHeaderName(from: line) {
                    finalProp = PropertyInfo(name: prop.name, type: prop.type, wrapper: prop.wrapper,
                                             isOptional: prop.isOptional, customKey: headerName, defaultValue: prop.defaultValue)
                }
                properties.append(finalProp)
            }
        } else if trimmed.hasPrefix("@RequestBody") {
            if let prop = parsePropertyLine(line: line, wrapper: "body") {
                properties.append(prop)
            }
        }

        i += 1
    }

    return properties
}

func parsePropertyLine(line: String, wrapper: String) -> PropertyInfo? {
    let pattern = #"var\s+(\w+):\s*([\w\[\]<>., ]+?)(\?)?\s*(?:=\s*(.+?))?\s*$"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))
    else {
        return nil
    }

    let name = extractMatch(from: line, match: match, at: 1) ?? ""
    let type = extractMatch(from: line, match: match, at: 2) ?? ""
    let isOptional = extractMatch(from: line, match: match, at: 3) != nil
    let defaultValue = extractMatch(from: line, match: match, at: 4)

    return PropertyInfo(
        name: name,
        type: type.trimmingCharacters(in: .whitespaces),
        wrapper: wrapper,
        isOptional: isOptional,
        customKey: nil,
        defaultValue: defaultValue?.trimmingCharacters(in: .whitespaces)
    )
}

func extractCustomKey(from line: String) -> String? {
    let pattern = #"key:\s*"([^"]+)""#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
          let range = Range(match.range(at: 1), in: line)
    else {
        return nil
    }
    return String(line[range])
}

func extractCustomHeaderName(from line: String) -> String? {
    // @CustomHeader("X-Custom-Header")에서 헤더 이름 추출
    let pattern = #"@CustomHeader\("([^"]+)"\)"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
          let range = Range(match.range(at: 1), in: line)
    else {
        return nil
    }
    return String(line[range])
}

func parseAPIRequestBlock(block: String, name: String, properties: [PropertyInfo], constants: [String: String] = [:]) -> APIRequestInfo? {
    func extract(_: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let range = Range(match.range(at: 1), in: block)
        else {
            return nil
        }
        return String(block[range])
    }

    func extractArray(_ key: String) -> [String] {
        guard let content = extract(key, pattern: key + #":\s*\[(.*?)\]"#) else { return [] }
        let pattern = #""([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        return matches.compactMap {
            guard let range = Range($0.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
    }

    func extractMultiline(_ key: String) -> String? {
        let tripleQuote = "\"\"\""
        let pattern = key + ":\\s*" + tripleQuote + "(.*?)" + tripleQuote
        guard let content = extract(key, pattern: pattern) else { return nil }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    guard let response = extract("response", pattern: #"response:\s*(\[?\w+\]?)(?:\.self)?"#) else {
        return nil
    }

    // baseURL 추출 (문자열 리터럴 또는 변수 참조)
    var baseURL = ""

    // 1. 문자열 리터럴: baseURL: "https://..."
    if let baseURLMatch = try? NSRegularExpression(pattern: #"baseURL:\s*"([^"]+)""#).firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
       let range = Range(baseURLMatch.range(at: 1), in: block)
    {
        baseURL = String(block[range])
    }
    // 2. 변수 참조: baseURL: constantName
    else if let varMatch = try? NSRegularExpression(pattern: #"baseURL:\s*(\w+)"#).firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
            let varRange = Range(varMatch.range(at: 1), in: block)
    {
        let varName = String(block[varRange])
        baseURL = constants[varName] ?? ""
    }

    // baseURL이 비어있으면 nil 반환
    guard !baseURL.isEmpty else {
        return nil
    }

    // errorResponses 파싱: errorResponses: [404: ErrorResponse.self, 500: ServerError.self]
    var errorResponses: [String: String] = [:]
    if block.contains("errorResponses:") {
        let errorPattern = #"(\d{3}):\s*(\w+)\.self"#
        if let regex = try? NSRegularExpression(pattern: errorPattern) {
            let nsRange = NSRange(block.startIndex..., in: block)
            let matches = regex.matches(in: block, range: nsRange)
            for match in matches {
                if let statusRange = Range(match.range(at: 1), in: block),
                   let typeRange = Range(match.range(at: 2), in: block)
                {
                    let statusCode = String(block[statusRange])
                    let typeName = String(block[typeRange])
                    errorResponses[statusCode] = typeName
                }
            }
        }
    }

    return APIRequestInfo(
        name: name,
        response: response,
        title: extract("title", pattern: #"title:\s*"([^"]+)""#) ?? name,
        description: extract("description", pattern: #"description:\s*"([^"]+)""#) ?? "",
        baseURL: baseURL,
        path: extract("path", pattern: #"path:\s*"([^"]+)""#) ?? "/",
        method: extract("method", pattern: #"method:\s*\.(\w+)"#) ?? "get",
        tags: extractArray("tags"),
        responseExample: extractMultiline("responseExample"),
        requestBodyExample: extractMultiline("requestBodyExample"),
        properties: properties,
        errorResponses: errorResponses
    )
}

func extractMatch(from string: String, match: NSTextCheckingResult, at index: Int) -> String? {
    guard let range = Range(match.range(at: index), in: string) else { return nil }
    return String(string[range])
}

// MARK: - Main

printInfo("AsyncNetwork OpenAPI Exporter")
print("")

// 인자 파싱
let args = CommandLine.arguments
var projectPaths: [String] = []
var documentTypePaths: [String] = []
var outputPath = "./docs/openapi.json"
var format = "json"
var title = "API Documentation"
var version = "1.0.0"
var description: String?

var i = 1
while i < args.count {
    let arg = args[i]

    switch arg {
    case "--project", "-p":
        if i + 1 < args.count {
            i += 1
            projectPaths.append(args[i])
        }
    case "--document-type-path", "-d":
        if i + 1 < args.count {
            i += 1
            documentTypePaths.append(args[i])
        }
    case "--output", "-o":
        if i + 1 < args.count {
            i += 1
            outputPath = args[i]
        }
    case "--format", "-f":
        if i + 1 < args.count {
            i += 1
            format = args[i].lowercased()
        }
    case "--title", "-t":
        if i + 1 < args.count {
            i += 1
            title = args[i]
        }
    case "--version", "-v":
        if i + 1 < args.count {
            i += 1
            version = args[i]
        }
    case "--description":
        if i + 1 < args.count {
            i += 1
            description = args[i]
        }
    case "--help", "-h":
        print("""
        사용법: swift ExportOpenAPI.swift [옵션]

        옵션:
          --project, -p <path>              @APIRequest 파일이 있는 경로 (여러 개 가능)
          --document-type-path, -d <path>   @DocumentedType 파일이 있는 경로 (여러 개 가능, 선택)
          --output, -o <path>               출력 파일 경로 (기본값: ./docs/openapi.json)
          --format, -f <format>             출력 형식 (json 또는 yaml, 기본값: json)
          --title, -t <title>               API 제목
          --version, -v <version>           API 버전
          --description <desc>               API 설명
          --help, -h                        도움말 표시

        예시:
          swift Scripts/OpenAPI/ExportOpenAPI.swift \\
            --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \\
            --document-type-path Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \\
            --output ./docs/openapi.json \\
            --format json \\
            --title "AsyncNetwork API" \\
            --version "1.0.0"
        """)
        exit(0)
    default:
        break
    }

    i += 1
}

// 기본값: 인자가 없으면 대화형
if projectPaths.isEmpty {
    printInfo("@APIRequest 파일 경로를 입력하세요:")
    if let input = readLine()?.trimmingCharacters(in: .whitespaces), !input.isEmpty {
        projectPaths = [input]
    } else {
        printError("프로젝트 경로가 필요합니다")
        exit(1)
    }
}

// DocumentType 경로가 있으면 출력 (현재는 파싱하지 않지만 경로는 받음)
if !documentTypePaths.isEmpty {
    printInfo("@DocumentedType 경로: \(documentTypePaths.joined(separator: ", "))")
}

// Output 디렉토리 생성
let fileManager = FileManager.default
let outputURL = URL(fileURLWithPath: outputPath)
let outputDir = outputURL.deletingLastPathComponent()

do {
    try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true, attributes: nil)
    printInfo("출력 디렉토리 생성: \(outputDir.path)")
} catch {
    printWarning("출력 디렉토리 생성 실패 (이미 존재할 수 있음): \(error.localizedDescription)")
}

// 실행
do {
    printInfo("@APIRequest 파싱 중...")
    let requests = try parseAPIRequests(from: projectPaths)
    printSuccess("\(requests.count)개의 API 요청 발견")

    printInfo("@Response/@TestableDTO 파싱 중...")
    let dtos = try parseTestableDTOs(from: projectPaths)
    printSuccess("\(dtos.count)개의 DTO 발견")
    if !dtos.isEmpty {
        printInfo("발견된 DTO: \(dtos.map { $0.name }.joined(separator: ", "))")
    }

    printInfo("@TestableSchemer 파싱 중...")
    let scemers = try parseTestableScemers(from: projectPaths)
    printSuccess("\(scemers.count)개의 Schemer 발견")
    if !scemers.isEmpty {
        printInfo("발견된 Schemer: \(scemers.map { $0.requestName }.joined(separator: ", "))")
    }

    printInfo("OpenAPI 스펙 생성 중...")
    let spec = generateSimpleOpenAPI(
        requests: requests,
        dtos: dtos,
        scemers: scemers,
        title: title,
        version: version,
        description: description,
        format: format
    )

    try spec.write(toFile: outputPath, atomically: true, encoding: .utf8)
    printSuccess("OpenAPI 스펙 저장 완료: \(outputPath)")
} catch {
    printError("실패: \(error)")
    exit(1)
}
