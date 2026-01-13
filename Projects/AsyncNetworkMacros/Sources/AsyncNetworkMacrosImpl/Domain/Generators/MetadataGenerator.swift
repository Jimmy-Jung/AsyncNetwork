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
    private let args: MacroArguments
    private let properties: [PropertyInfo]

    public init(
        args: MacroArguments,
        properties: [PropertyInfo]
    ) {
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
        let parametersArray = generateParametersArray()

        let titleEscaped = args.title.replacingOccurrences(of: "\"", with: "\\\"")
        let descriptionEscaped = args.description.replacingOccurrences(of: "\"", with: "\\\"")
        let tagsArray = args.tags.map { "\"\($0)\"" }.joined(separator: ", ")

        return """
        public var metadata: EndpointMetadata {
            EndpointMetadata(
                title: "\(raw: titleEscaped)",
                description: "\(raw: descriptionEscaped)",
                method: "\(raw: args.method.uppercased())",
                path: "\(raw: args.path)",
                tags: [\(raw: tagsArray)],
                parameters: \(raw: parametersArray)
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
}
