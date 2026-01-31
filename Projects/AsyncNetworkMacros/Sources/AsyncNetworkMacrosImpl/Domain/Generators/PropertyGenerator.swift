import SwiftSyntax

public struct PropertyGenerator: CodeGenerator {
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
    
    private func hasHeaderFields() -> Bool {
        properties.contains(where: \.isHeader)
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
        let methodValue = formatHTTPMethod()
        return createPropertyDeclaration(
            name: "method",
            type: "HTTPMethod",
            value: methodValue
        )
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

    private func formatHTTPMethod() -> String {
        ".\(args.method.lowercased())"
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
