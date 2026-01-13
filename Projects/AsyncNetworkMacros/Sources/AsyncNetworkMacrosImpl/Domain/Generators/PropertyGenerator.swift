//
//  PropertyGenerator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// 매크로 기본 프로퍼티 생성기
///
/// 이 클래스는 `@APIRequest` 매크로에서 생성할 기본 프로퍼티들을 생성합니다:
/// - `typealias Response`
/// - `var baseURLString: String`
/// - `var method: HTTPMethod`
///
/// ## 사용 예시
/// ```swift
/// let generator = PropertyGenerator(args: macroArguments)
/// let declarations = generator.generate()
/// // [typealias Response = Post, var baseURLString: String, var method: HTTPMethod]
/// ```
public struct PropertyGenerator: CodeGenerator {
    private let args: MacroArguments

    public init(args: MacroArguments) {
        self.args = args
    }

    // MARK: - CodeGenerator

    public func generate() -> [DeclSyntax] {
        var declarations: [DeclSyntax] = []

        declarations.append(generateResponseTypealias())
        declarations.append(generateBaseURLString())
        declarations.append(generateMethod())

        return declarations
    }

    // MARK: - Private Methods

    /// `typealias Response = ResponseType` 생성
    private func generateResponseTypealias() -> DeclSyntax {
        return """
        public typealias Response = \(raw: args.responseType)
        """
    }

    /// `var baseURLString: String { ... }` 생성
    private func generateBaseURLString() -> DeclSyntax {
        if args.isBaseURLLiteral {
            // 문자열 리터럴인 경우 그대로 반환
            return """
            public var baseURLString: String {
                "\(raw: args.baseURL)"
            }
            """
        } else {
            // 표현식인 경우 (예: APIConfiguration.baseURL)
            return """
            public var baseURLString: String {
                \(raw: args.baseURL)
            }
            """
        }
    }

    /// `var method: HTTPMethod { ... }` 생성
    private func generateMethod() -> DeclSyntax {
        return """
        public var method: HTTPMethod {
            .\(raw: args.method.lowercased())
        }
        """
    }
}
