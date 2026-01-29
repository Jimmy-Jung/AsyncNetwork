import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - APIDocumentMacroError

public enum APIDocumentMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    case onlyApplicableToStruct
    case missingAPIRequest

    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@APIDocument can only be applied to a struct"
        case .missingAPIRequest:
            return """
            @APIDocument requires @APIRequest to be declared first.

            Usage:
            @APIRequest(...)
            @APIDocument(...)
            struct YourRequest { }
            """
        }
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "APIDocumentMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - APIDocumentMacroImpl

public struct APIDocumentMacroImpl: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let structDecl = try validateStructDeclaration(
            declaration,
            node: node,
            context: context
        )

        guard let apiRequestAttribute = findAPIRequestAttribute(declaration: declaration) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIDocumentMacroError.missingAPIRequest
            )
            context.diagnose(diagnostic)
            return []
        }

        let apiRequestArgs = try parseAPIRequestArguments(
            attribute: apiRequestAttribute,
            context: context
        )

        let documentArgs = parseAPIDocumentArguments(
            node: node,
            context: context
        )

        let scanner = PropertyWrapperScanner()
        let properties = scanner.scan(from: structDecl)

        let metadataDecl = generateMetadata(
            typeName: structDecl.name.text,
            apiRequestArgs: apiRequestArgs,
            documentArgs: documentArgs,
            properties: properties
        )

        return [metadataDecl]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let ext: DeclSyntax =
            """
            extension \(type.trimmed): DocumentableAPIRequest {}
            """

        guard let extensionDeclSyntax = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    private static func escapeForStringLiteral(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    private static func validateStructDeclaration(
        _ declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> StructDeclSyntax {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIDocumentMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            throw APIDocumentMacroError.onlyApplicableToStruct
        }
        return structDecl
    }

    private static func findAPIRequestAttribute(declaration: some DeclGroupSyntax) -> AttributeSyntax? {
        for attribute in declaration.attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  customAttribute.attributeName.trimmedDescription == "APIRequest"
            else {
                continue
            }
            return customAttribute
        }
        return nil
    }

    private static func parseAPIRequestArguments(
        attribute: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> MacroArguments {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            throw APIRequestMacroError.missingArguments
        }

        let expressionParser = ExpressionParser()
        let pathParser = PathParser()

        guard let responseExpr = findArgument(labeled: "response", in: arguments),
              let responseType = try? expressionParser.extractTypeName(from: responseExpr)
        else {
            throw APIRequestMacroError.missingRequiredArgument("response")
        }

        guard let baseURLExpr = findArgument(labeled: "baseURL", in: arguments) else {
            throw APIRequestMacroError.missingRequiredArgument("baseURL")
        }

        let (baseURL, isBaseURLLiteral): (String, Bool) = {
            if let literal = try? expressionParser.extractString(from: baseURLExpr) {
                return (literal, true)
            } else {
                let expression = expressionParser.extractStringOrExpression(from: baseURLExpr)
                return (expression, false)
            }
        }()

        guard let pathExpr = findArgument(labeled: "path", in: arguments),
              let path = try? expressionParser.extractString(from: pathExpr)
        else {
            throw APIRequestMacroError.missingRequiredArgument("path")
        }

        guard let methodExpr = findArgument(labeled: "method", in: arguments),
              let method = try? expressionParser.extractEnumCase(from: methodExpr)
        else {
            throw APIRequestMacroError.missingRequiredArgument("method")
        }

        let title: String = {
            guard let titleExpr = findArgument(labeled: "title", in: arguments),
                  let titleValue = try? expressionParser.extractString(from: titleExpr)
            else {
                return ""
            }
            return titleValue
        }()

        let description: String = {
            guard let descExpr = findArgument(labeled: "description", in: arguments),
                  let descValue = try? expressionParser.extractString(from: descExpr)
            else {
                return ""
            }
            return descValue
        }()

        let tags: [String] = {
            guard let tagsExpr = findArgument(labeled: "tags", in: arguments) else {
                return []
            }
            return expressionParser.extractStringArray(from: tagsExpr)
        }()

        let optionalPathParameters = pathParser.extractOptionalParameters(from: path)

        return MacroArguments(
            responseType: responseType,
            title: title,
            description: description,
            baseURL: baseURL,
            isBaseURLLiteral: isBaseURLLiteral,
            path: path,
            method: method,
            tags: tags,
            optionalPathParameters: optionalPathParameters
        )
    }

    private static func findArgument(
        labeled label: String,
        in arguments: LabeledExprListSyntax
    ) -> ExprSyntax? {
        for argument in arguments where argument.label?.text == label {
            return argument.expression
        }
        return nil
    }

    private static func parseAPIDocumentArguments(
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> DocumentArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return DocumentArguments(title: "", description: "", tags: [])
        }

        let expressionParser = ExpressionParser()

        let title: String = {
            guard let expr = findArgument(labeled: "title", in: arguments),
                  let value = try? expressionParser.extractString(from: expr)
            else {
                return ""
            }
            return value
        }()

        let description: String = {
            guard let expr = findArgument(labeled: "description", in: arguments),
                  let value = try? expressionParser.extractString(from: expr)
            else {
                return ""
            }
            return value
        }()

        let tags: [String] = {
            guard let expr = findArgument(labeled: "tags", in: arguments) else {
                return []
            }
            return expressionParser.extractStringArray(from: expr)
        }()

        return DocumentArguments(title: title, description: description, tags: tags)
    }

    private static func generateMetadata(
        typeName: String,
        apiRequestArgs: MacroArguments,
        documentArgs: DocumentArguments,
        properties: [PropertyWrapperInfo]
    ) -> DeclSyntax {
        let tagsCode = documentArgs.tags
            .map { #""\#(escapeForStringLiteral($0))""# }
            .joined(separator: ", ")

        let escapedTitle = escapeForStringLiteral(documentArgs.title)
        let escapedDescription = escapeForStringLiteral(documentArgs.description)

        let headerEntries = properties
            .filter { $0.wrapperType == "HeaderField" || $0.wrapperType == "CustomHeader" }
            .compactMap { info -> String? in
                guard let key = info.headerKey,
                      let defaultValue = info.defaultValue else {
                    return nil
                }
                let escapedKey = escapeForStringLiteral(key)
                let escapedValue = escapeForStringLiteral(defaultValue)
                return #""\#(escapedKey)": "\#(escapedValue)""#
            }

        let headersCode = headerEntries.isEmpty
            ? "[:]"
            : "[\(headerEntries.joined(separator: ", "))]"

        let parameterNames = properties
            .filter { ["PathParameter", "QueryParameter"].contains($0.wrapperType) }
            .map { #""\#(escapeForStringLiteral($0.name))""# }

        let parametersCode = parameterNames.isEmpty
            ? "[]"
            : "[\(parameterNames.joined(separator: ", "))]"

        let baseURLCode = apiRequestArgs.isBaseURLLiteral
            ? #""\#(escapeForStringLiteral(apiRequestArgs.baseURL))""#
            : apiRequestArgs.baseURL

        let escapedPath = escapeForStringLiteral(apiRequestArgs.path)
        let escapedTypeName = escapeForStringLiteral(typeName)
        let uppercasedMethod = apiRequestArgs.method.uppercased()
        let escapedResponseType = escapeForStringLiteral(apiRequestArgs.responseType)

        return """
        public static var metadata: EndpointMetadata {
            EndpointMetadata(
                id: "\(raw: escapedTypeName)",
                title: "\(raw: escapedTitle)",
                description: "\(raw: escapedDescription)",
                method: "\(raw: uppercasedMethod)",
                path: "\(raw: escapedPath)",
                baseURLString: \(raw: baseURLCode),
                headers: \(raw: headersCode),
                tags: [\(raw: tagsCode)],
                parameters: \(raw: parametersCode),
                responseTypeName: "\(raw: escapedResponseType)"
            )
        }
        """
    }
}
