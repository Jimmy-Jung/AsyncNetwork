import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AsyncNetworkMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIRequestMacroImpl.self,
        ResponseTestableMacroImpl.self
    ]
}
