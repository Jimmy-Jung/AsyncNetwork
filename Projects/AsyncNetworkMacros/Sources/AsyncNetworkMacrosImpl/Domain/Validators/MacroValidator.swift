public protocol MacroValidator {
    func validate() throws
}

public struct APIRequestMacroValidator: MacroValidator {
    public let context: MacroContext

    public init(context: MacroContext) {
        self.context = context
    }

    public func validate() throws {
        guard context.structDecl != nil else {
            throw MacroError.onlyApplicableToStruct
        }

        guard context.arguments != nil else {
            throw MacroError.missingArguments
        }
    }
}
