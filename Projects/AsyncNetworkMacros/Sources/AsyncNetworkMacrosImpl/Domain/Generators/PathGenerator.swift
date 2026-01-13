//
//  PathGenerator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// 경로 프로퍼티 생성기
///
/// 이 클래스는 `@APIRequest` 매크로에서 `path` 프로퍼티를 생성합니다.
/// 경로에 플레이스홀더가 있는 경우 동적 경로를 생성하고,
/// 없는 경우 정적 경로를 생성합니다.
///
/// ## 동적 경로 예시
/// ```swift
/// // path: "/posts/{id}/comments"
/// public var path: String {
///     "/posts/\(id)/comments"
/// }
/// ```
///
/// ## 정적 경로 예시
/// ```swift
/// // path: "/posts"
/// public var path: String {
///     "/posts"
/// }
/// ```
public struct PathGenerator: CodeGenerator {
    private let args: MacroArguments
    private let pathParser: PathParser
    private let properties: [PropertyInfo]

    public init(
        args: MacroArguments,
        pathParser: PathParser,
        properties: [PropertyInfo]
    ) {
        self.args = args
        self.pathParser = pathParser
        self.properties = properties
    }

    // MARK: - CodeGenerator

    public func generate() -> [DeclSyntax] {
        let placeholders = pathParser.extractPlaceholders(from: args.path)

        if placeholders.isEmpty {
            return [generateStaticPath()]
        } else {
            return [generateDynamicPath(placeholders: placeholders)]
        }
    }

    // MARK: - Private Methods

    /// 정적 경로 생성 (플레이스홀더 없음)
    private func generateStaticPath() -> DeclSyntax {
        let normalizedPath = pathParser.normalize(args.path)

        return """
        public var path: String {
            "\(raw: normalizedPath)"
        }
        """
    }

    /// 동적 경로 생성 (플레이스홀더 있음)
    private func generateDynamicPath(placeholders: [String]) -> DeclSyntax {
        let normalizedPath = pathParser.normalize(args.path)
        var pathWithInterpolations = normalizedPath

        // {id} -> \(id) 형태로 변환
        for placeholder in placeholders {
            let pattern = "{\(placeholder)}"
            let replacement = "\\(\(placeholder))"
            pathWithInterpolations = pathWithInterpolations.replacingOccurrences(
                of: pattern,
                with: replacement
            )
        }

        return """
        public var path: String {
            "\(raw: pathWithInterpolations)"
        }
        """
    }
}
