import SwiftSyntax

// MARK: - StructDeclSyntax Extensions

public extension StructDeclSyntax {
    var variableDeclarations: [VariableDeclSyntax] {
        memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
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

// MARK: - TypeAnnotationSyntax Extensions

public extension TypeAnnotationSyntax {
    var isOptional: Bool {
        type.trimmedDescription.hasSuffix("?")
    }
}

// MARK: - PatternBindingSyntax Extensions

public extension PatternBindingSyntax {
    var propertyName: String? {
        pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }
}
