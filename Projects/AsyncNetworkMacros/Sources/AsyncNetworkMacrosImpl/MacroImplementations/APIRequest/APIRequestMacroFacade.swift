import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct APIRequestMacroFacade {
    private let pathParser: PathParser
    private let expressionParser: ExpressionParser

    public init() {
        pathParser = PathParser()
        expressionParser = ExpressionParser()
    }

    public func expand(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let macroContext = MacroContext(
            node: node,
            declaration: declaration,
            expansionContext: context
        )

        guard let structDecl = macroContext.structDecl else {
            throw MacroError.onlyApplicableToStruct
        }

        let argumentParser = APIRequestArgumentParser(
            context: macroContext,
            expressionParser: expressionParser,
            pathParser: pathParser
        )

        let args = try argumentParser.parse()
        let properties = collectProperties(from: structDecl)

        let validator = PropertyWrapperValidator(
            context: macroContext,
            args: args,
            pathParser: pathParser
        )

        let suggestions = validator.validateAndSuggest()

        for suggestion in suggestions {
            let diagnostic = suggestion.toDiagnostic(node: structDecl)
            context.diagnose(diagnostic)
        }

        var declarations: [DeclSyntax] = []

        let propertyGenerator = PropertyGenerator(args: args, properties: properties)
        declarations.append(contentsOf: propertyGenerator.generate())

        let pathGenerator = PathGenerator(
            args: args,
            pathParser: pathParser,
            properties: properties
        )
        declarations.append(contentsOf: pathGenerator.generate())

        return declarations
    }

    private func collectProperties(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for variableDecl in structDecl.variableDeclarations {
            guard let propertyName = variableDecl.firstPropertyName,
                  let typeAnnotation = variableDecl.firstTypeAnnotation
            else {
                continue
            }

            let wrapperType = variableDecl.propertyWrapperType
            let isRequired = !typeAnnotation.isOptional
            let defaultValue = variableDecl.firstInitializer?.value.trimmedDescription
            var headerKey: String?
            if let wrapperAttribute = variableDecl.propertyWrapperAttribute,
               let wrapperName = wrapperAttribute.name,
               wrapperName == "HeaderField" || wrapperName == "CustomHeader",
               let keyArg = wrapperAttribute.argument(labeled: "key") {
                if let literal = try? expressionParser.extractString(from: keyArg) {
                    headerKey = literal
                } else if let enumCase = try? expressionParser.extractEnumCase(from: keyArg) {
                    headerKey = enumCase
                }
            }

            properties.append(PropertyInfo(
                name: propertyName,
                type: typeAnnotation.trimmedDescription,
                wrapperType: wrapperType,
                isRequired: isRequired,
                headerKey: headerKey,
                defaultValue: defaultValue
            ))
        }

        return properties
    }
}
