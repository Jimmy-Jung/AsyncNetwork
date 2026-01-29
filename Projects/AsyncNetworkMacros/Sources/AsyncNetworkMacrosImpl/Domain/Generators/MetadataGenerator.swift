//
//  MetadataGenerator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// EndpointMetadata 생성기
///
/// 이 클래스는 `@APIRequest` 매크로에서 `metadata` 프로퍼티를 생성합니다.
/// 메타데이터는 API 문서화 및 디버깅을 위한 정보를 포함합니다.
///
/// ## 생성 예시
/// ```swift
/// public var metadata: EndpointMetadata {
///     EndpointMetadata(
///         title: "Get Post",
///         description: "Retrieve a post by ID",
///         method: "GET",
///         path: "/posts/{id}",
///         tags: ["Posts"],
///         parameters: [
///             .path(name: "id", type: "Int", required: true),
///             .query(name: "page", type: "Int", required: false)
///         ]
///     )
/// }
/// ```
public struct MetadataGenerator: CodeGenerator {
    private let typeName: String
    private let args: MacroArguments
    private let properties: [PropertyInfo]

    public init(
        typeName: String,
        args: MacroArguments,
        properties: [PropertyInfo]
    ) {
        self.typeName = typeName
        self.args = args
        self.properties = properties
    }

    // MARK: - CodeGenerator

    public func generate() -> [DeclSyntax] {
        return [generateMetadata()]
    }

    // MARK: - Private Methods

    /// EndpointMetadata 생성
    private func generateMetadata() -> DeclSyntax {
        // 완전한 escape 처리 (백슬래시, 따옴표, 줄바꿈)
        let titleEscaped = escapeString(args.title)
        let descriptionEscaped = escapeString(args.description)
        let tagsArray = args.tags.map { "\"\($0)\"" }.joined(separator: ", ")
        
        // headers 딕셔너리 생성
        var headerEntries: [String] = []
        for property in properties {
            if property.wrapperType == "HeaderField" || property.wrapperType == "CustomHeader",
               let headerKey = property.headerKey,
               let defaultValue = property.defaultValue {
                let escapedValue = defaultValue
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                headerEntries.append("\"\(headerKey)\": \"\(escapedValue)\"")
            }
        }
        let headersString = headerEntries.isEmpty ? "[:]" : "[\(headerEntries.joined(separator: ", "))]"
        
        // parameters 배열을 문자열 배열로 변환
        let parameterNames = properties
            .filter { ["PathParameter", "QueryParameter"].contains($0.wrapperType) }
            .map { "\"\($0.name)\"" }
        let parametersStringArray = parameterNames.isEmpty ? "[]" : "[\(parameterNames.joined(separator: ", "))]"

        return """
        public static var metadata: EndpointMetadata {
            EndpointMetadata(
                id: "\(raw: typeName)",
                title: "\(raw: titleEscaped)",
                description: "\(raw: descriptionEscaped)",
                method: "\(raw: args.method.uppercased())",
                path: "\(raw: args.path)",
                baseURLString: \(raw: args.baseURL),
                headers: \(raw: headersString),
                tags: [\(raw: tagsArray)],
                parameters: \(raw: parametersStringArray),
                responseTypeName: "\(raw: args.responseType)"
            )
        }
        """
    }

    /// parameters 배열 생성
    private func generateParametersArray() -> String {
        var parameters: [String] = []

        for property in properties {
            guard let wrapperType = property.wrapperType else {
                continue
            }

            let name = property.name
            let type = property.type.replacingOccurrences(of: "?", with: "")
            let required = property.isRequired

            switch wrapperType {
            case "PathParameter":
                parameters.append(".path(name: \"\(name)\", type: \"\(type)\", required: \(required))")

            case "QueryParameter":
                parameters.append(".query(name: \"\(name)\", type: \"\(type)\", required: \(required))")

            case "HeaderField", "CustomHeader":
                if let headerKey = property.headerKey {
                    parameters.append(".header(name: \"\(headerKey)\", type: \"\(type)\", required: \(required))")
                } else {
                    parameters.append(".header(name: \"\(name)\", type: \"\(type)\", required: \(required))")
                }

            case "RequestBody":
                parameters.append(".body(type: \"\(type)\")")

            default:
                break
            }
        }

        if parameters.isEmpty {
            return "[]"
        }

        return "[\n        " + parameters.joined(separator: ",\n        ") + "\n    ]"
    }
    
    /// 문자열을 안전하게 escape 처리
    /// - 백슬래시, 따옴표, 줄바꿈, 캐리지 리턴, 탭을 처리
    private func escapeString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
