import SwiftSyntax

struct FixtureJSONExtractor {
    func extract(from structDecl: StructDeclSyntax) -> String? {
        for attribute in structDecl.attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  customAttribute.attributeName.trimmedDescription == "ResponseDocument",
                  let arguments = customAttribute.arguments?.as(LabeledExprListSyntax.self)
            else {
                continue
            }

            for argument in arguments where argument.label?.text == "fixtureJSON" {
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    var result = ""
                    for segment in stringLiteral.segments {
                        if let stringSegment = segment.as(StringSegmentSyntax.self) {
                            result += stringSegment.content.text
                        }
                    }
                    return result
                }
            }
        }

        return nil
    }
}
