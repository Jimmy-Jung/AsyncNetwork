import SwiftSyntax

struct PropertyWrapperScanner {
    func scan(from structDecl: StructDeclSyntax) -> [PropertyWrapperInfo] {
        var result: [PropertyWrapperInfo] = []

        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            guard let wrapperAttribute = extractPropertyWrapperAttribute(from: variableDecl) else {
                continue
            }

            let wrapperType = wrapperAttribute.attributeName.trimmedDescription

            for binding in variableDecl.bindings {
                guard let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                      let propertyType = extractPropertyType(from: binding)
                else {
                    continue
                }

                let headerKey: String? = {
                    guard wrapperType == "HeaderField" || wrapperType == "CustomHeader",
                          let arguments = wrapperAttribute.arguments?.as(LabeledExprListSyntax.self) else {
                        return nil
                    }

                    for argument in arguments where argument.label?.text == "key" {
                        if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                            let enumCase = memberAccess.declName.baseName.text
                            return HeaderKeyMapper.map(enumCase)
                        } else if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                                  let firstSegment = stringLiteral.segments.first,
                                  let stringSegment = firstSegment.as(StringSegmentSyntax.self) {
                            return stringSegment.content.text
                        }
                    }

                    return nil
                }()

                let defaultValue: String? = {
                    guard let initClause = binding.initializer else {
                        return nil
                    }

                    if let stringLiteral = initClause.value.as(StringLiteralExprSyntax.self) {
                        var stringValue = ""
                        for segment in stringLiteral.segments {
                            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                                stringValue += stringSegment.content.text
                            }
                        }
                        return stringValue
                    }

                    return initClause.value.trimmedDescription
                }()

                let info = PropertyWrapperInfo(
                    name: propertyName,
                    type: propertyType,
                    wrapperType: wrapperType,
                    headerKey: headerKey,
                    defaultValue: defaultValue
                )

                result.append(info)
            }
        }

        return result
    }

    private func extractPropertyWrapperAttribute(from variableDecl: VariableDeclSyntax) -> AttributeSyntax? {
        let validWrappers = [
            "PathParameter", "QueryParameter",
            "HeaderField", "CustomHeader",
            "RequestBody", "FormData"
        ]

        for attribute in variableDecl.attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  validWrappers.contains(customAttribute.attributeName.trimmedDescription)
            else {
                continue
            }
            return customAttribute
        }

        return nil
    }

    private func extractPropertyType(from binding: PatternBindingSyntax) -> String? {
        binding.typeAnnotation?.type.trimmedDescription
    }
}
