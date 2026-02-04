import SwiftSyntax

public struct PropertyGenerator {
    private let args: MacroArguments
    private let properties: [PropertyInfo]

    public init(args: MacroArguments, properties: [PropertyInfo] = []) {
        self.args = args
        self.properties = properties
    }

    public func generate() -> [DeclSyntax] {
        var decls: [DeclSyntax] = [
            generateResponseTypealias(),
            generateBaseURLString(),
            generateMethod()
        ]

        // @HeaderField나 @CustomHeader가 있으면 headers 프로퍼티 생성
        if properties.contains(where: \.isHeader) {
            decls.append(generateHeaders())
        }

        return decls
    }
}

extension PropertyGenerator {
    private func generateResponseTypealias() -> DeclSyntax {
        """
        public typealias Response = \(raw: args.responseType)
        """
    }

    private func generateBaseURLString() -> DeclSyntax {
        let baseURLValue = formatBaseURL()
        return createPropertyDeclaration(
            name: "baseURLString",
            type: "String",
            value: baseURLValue
        )
    }

    private func generateMethod() -> DeclSyntax {
        // Phase 3: 동적 메서드 지원
        if args.isDynamicMethod, let propertyName = args.dynamicMethodProperty {
            // 동적: 사용자가 정의한 프로퍼티를 참조
            return createPropertyDeclaration(
                name: "method",
                type: "HTTPMethod",
                value: propertyName
            )
        } else {
            // 정적: enum case (.get, .post 등)
            // args.method가 이미 enum case 이름("get", "post" 등)이므로 점을 붙여야 함
            let methodValue = ".\(args.method.lowercased())"
            return createPropertyDeclaration(
                name: "method",
                type: "HTTPMethod",
                value: methodValue
            )
        }
    }

    private func generateHeaders() -> DeclSyntax {
        let headerProps = properties.filter(\.isHeader)

        let headerMappings = headerProps.compactMap { prop -> String? in
            guard let key = prop.headerKey else { return nil }
            let propName = prop.name

            if prop.isRequired {
                return #""\#(key)": \#(propName)"#
            } else {
                return nil // Optional headers are handled separately
            }
        }

        let optionalHeaderMappings = headerProps.compactMap { prop -> String? in
            guard let key = prop.headerKey else { return nil }
            let propName = prop.name

            if prop.isOptional {
                return #"if let \#(propName) = \#(propName) { dict["\#(key)"] = \#(propName) }"#
            } else {
                return nil
            }
        }

        var bodyLines: [String] = []

        if !headerMappings.isEmpty {
            bodyLines.append("var dict: [String: String] = [")
            bodyLines.append(contentsOf: headerMappings.map { "    \($0)," })
            bodyLines.append("]")
        } else {
            bodyLines.append("var dict: [String: String] = [:]")
        }

        if !optionalHeaderMappings.isEmpty {
            bodyLines.append(contentsOf: optionalHeaderMappings)
        }

        bodyLines.append("return dict.isEmpty ? nil : dict")

        let body = bodyLines.joined(separator: "\n            ")

        return """
        public var headers: [String: String]? {
            \(raw: body)
        }
        """
    }
}

extension PropertyGenerator {
    private func formatBaseURL() -> String {
        args.isBaseURLLiteral
            ? #""\#(args.baseURL)""#
            : args.baseURL
    }

    private func createPropertyDeclaration(
        name: String,
        type: String,
        value: String
    ) -> DeclSyntax {
        """
        public var \(raw: name): \(raw: type) {
            \(raw: value)
        }
        """
    }
}
