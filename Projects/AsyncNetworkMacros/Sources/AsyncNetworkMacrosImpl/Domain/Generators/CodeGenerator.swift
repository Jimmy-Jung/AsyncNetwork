import SwiftSyntax

public protocol CodeGenerator {
    func generate() -> [DeclSyntax]
}
