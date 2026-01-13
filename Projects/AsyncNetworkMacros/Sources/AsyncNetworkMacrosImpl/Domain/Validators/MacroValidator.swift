//
//  MacroValidator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

/// 매크로 적용 대상 검증 프로토콜
public protocol MacroValidator {
    /// 매크로 적용 가능 여부 검증
    /// - Throws: 검증 실패 시 MacroError
    func validate() throws
}

/// APIRequest 매크로 검증자
public struct APIRequestMacroValidator: MacroValidator {
    public let context: MacroContext

    public init(context: MacroContext) {
        self.context = context
    }

    public func validate() throws {
        // 1. 구조체 검증
        guard context.structDecl != nil else {
            throw MacroError.onlyApplicableToStruct
        }

        // 2. 필수 인자 검증
        guard context.arguments != nil else {
            throw MacroError.missingArguments
        }
    }
}
