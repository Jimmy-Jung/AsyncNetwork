import SwiftSyntax

// MARK: - StructDeclSyntax Extensions

public extension StructDeclSyntax {
    var variableDeclarations: [VariableDeclSyntax] {
        memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }
    }

    var propertyNames: Set<String> {
        var names: Set<String> = []

        for member in memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        names.insert(identifier.identifier.text)
                    }
                }
            }

            if let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self) {
                names.insert(typealiasDecl.name.text)
            }
        }

        return names
    }

    func hasProperty(named name: String) -> Bool {
        propertyNames.contains(name)
    }

    var hasInitializer: Bool {
        memberBlock.members.contains { member in
            member.decl.is(InitializerDeclSyntax.self)
        }
    }
}

// MARK: - VariableDeclSyntax Extensions

public extension VariableDeclSyntax {
    var propertyWrapperAttribute: AttributeSyntax? {
        let validWrappers = [
            "PathParameter", "QueryParameter",
            "HeaderField", "CustomHeader",
            "RequestBody", "FormData"
        ]

        for attribute in attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  let identifier = customAttribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                  validWrappers.contains(identifier)
            else {
                continue
            }
            return customAttribute
        }

        return nil
    }

    var propertyWrapperType: String? {
        propertyWrapperAttribute?.attributeName.trimmedDescription
    }

    var firstPropertyName: String? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }

    var firstTypeAnnotation: TypeAnnotationSyntax? {
        bindings.first?.typeAnnotation
    }

    var firstInitializer: InitializerClauseSyntax? {
        bindings.first?.initializer
    }
}

// MARK: - AttributeSyntax Extensions

public extension AttributeSyntax {
    var name: String? {
        attributeName.as(IdentifierTypeSyntax.self)?.name.text
    }

    var labeledArguments: LabeledExprListSyntax? {
        arguments?.as(LabeledExprListSyntax.self)
    }

    func argument(labeled label: String) -> ExprSyntax? {
        guard let arguments = labeledArguments else { return nil }

        for argument in arguments where argument.label?.text == label {
            return argument.expression
        }

        return nil
    }
}

// MARK: - DeclGroupSyntax Extensions

public extension DeclGroupSyntax {
    func findAttribute(named name: String) -> AttributeSyntax? {
        for attribute in attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  customAttribute.name == name
            else {
                continue
            }
            return customAttribute
        }
        return nil
    }

    func findAttributes(named names: [String]) -> [AttributeSyntax] {
        var result: [AttributeSyntax] = []

        for attribute in attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  let attrName = customAttribute.name,
                  names.contains(attrName)
            else {
                continue
            }
            result.append(customAttribute)
        }

        return result
    }
}

// MARK: - TypeAnnotationSyntax Extensions

public extension TypeAnnotationSyntax {
    var isOptional: Bool {
        type.trimmedDescription.hasSuffix("?")
    }

    var baseTypeName: String {
        type.trimmedDescription.replacingOccurrences(of: "?", with: "")
    }
}

// MARK: - PatternBindingSyntax Extensions

public extension PatternBindingSyntax {
    var propertyName: String? {
        pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }

    var defaultValue: String? {
        initializer?.value.trimmedDescription
    }
}
