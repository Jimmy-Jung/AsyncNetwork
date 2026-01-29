import SwiftSyntax

struct TestableDTOArgumentParser {
    func parse(from node: AttributeSyntax) throws -> TestableDTOArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return TestableDTOArguments(
                fixtureJSON: nil,
                includeBuilder: true,
                defaultArrayCount: 5,
                generateDocumentation: true
            )
        }

        var fixtureJSON: String?
        var includeBuilder = true
        var defaultArrayCount = 5
        var generateDocumentation = true

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "mockStrategy":
                // Deprecated: 무시 (하위 호환성)
                break
            case "fixtureJSON":
                fixtureJSON = try? ExpressionParser().extractString(from: expr)
            case "includeBuilder":
                if let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) {
                    includeBuilder = boolLiteral.literal.text == "true"
                }
            case "defaultArrayCount":
                if let intLiteral = expr.as(IntegerLiteralExprSyntax.self) {
                    defaultArrayCount = Int(intLiteral.literal.text) ?? 5
                }
            case "generateDocumentation":
                if let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) {
                    generateDocumentation = boolLiteral.literal.text == "true"
                }
            default:
                break
            }
        }

        return TestableDTOArguments(
            fixtureJSON: fixtureJSON,
            includeBuilder: includeBuilder,
            defaultArrayCount: defaultArrayCount,
            generateDocumentation: generateDocumentation
        )
    }
}
