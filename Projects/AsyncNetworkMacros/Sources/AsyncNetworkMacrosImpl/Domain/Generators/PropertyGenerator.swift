import SwiftSyntax

public struct PropertyGenerator: CodeGenerator {
    private let args: MacroArguments

    public init(args: MacroArguments) {
        self.args = args
    }

    public func generate() -> [DeclSyntax] {
        [
            generateResponseTypealias(),
            generateBaseURLString(),
            generateMethod()
        ]
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
