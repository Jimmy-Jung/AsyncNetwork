//
//  PropertyWrapperValidator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// Property Wrapper 사용의 유효성을 검증하고 제안을 생성
///
/// 이 클래스는 프로퍼티에 적절한 Property Wrapper가 사용되었는지 검증하고,
/// 누락되었거나 잘못 사용된 경우 제안을 생성합니다.
///
/// ## 검증 항목
/// - PathParameter: 경로 플레이스홀더와 일치하는지
/// - QueryParameter: GET 메서드에 적합한지
/// - RequestBody: POST/PUT/PATCH 메서드에 적합한지
/// - HeaderField: 헤더 관련 프로퍼티인지
///
/// ## 사용 예시
/// ```swift
/// let validator = PropertyWrapperValidator(
///     context: macroContext,
///     args: macroArguments,
///     pathParser: PathParser()
/// )
///
/// let suggestions = validator.validateAndSuggest()
/// for suggestion in suggestions {
///     context.diagnoseWarning(on: node, message: suggestion)
/// }
/// ```
public struct PropertyWrapperValidator {
    public let context: MacroContext
    public let args: MacroArguments
    public let pathParser: PathParser

    /// 생성된 프로퍼티 (검증에서 제외)
    private let generatedProperties: Set<String> = [
        "Response", "baseURLString", "path", "method", "headers", "timeout", "metadata"
    ]

    public init(
        context: MacroContext,
        args: MacroArguments,
        pathParser: PathParser
    ) {
        self.context = context
        self.args = args
        self.pathParser = pathParser
    }

    // MARK: - Public Methods

    /// 모든 프로퍼티를 검증하고 제안 생성
    ///
    /// - Returns: 생성된 제안 목록
    public func validateAndSuggest() -> [PropertyWrapperSuggestion] {
        guard let structDecl = context.structDecl else {
            return []
        }

        var suggestions: [PropertyWrapperSuggestion] = []

        for variableDecl in structDecl.variableDeclarations {
            guard let propertyName = variableDecl.firstPropertyName,
                  !generatedProperties.contains(propertyName),
                  let typeAnnotation = variableDecl.firstTypeAnnotation
            else {
                continue
            }

            let propertyInfo = PropertyInfo(
                name: propertyName,
                type: typeAnnotation.trimmedDescription,
                wrapperType: variableDecl.propertyWrapperType,
                isRequired: !typeAnnotation.isOptional
            )

            // Property Wrapper가 있으면 검증
            if let wrapperType = propertyInfo.wrapperType {
                if let suggestion = validate(wrapperType: wrapperType, propertyInfo: propertyInfo) {
                    suggestions.append(suggestion)
                }
            }
            // Property Wrapper가 없으면 제안
            else {
                if let suggestion = suggest(for: propertyInfo) {
                    suggestions.append(suggestion)
                }
            }
        }

        return suggestions
    }

    // MARK: - Validation

    /// Property Wrapper 사용의 유효성 검증
    private func validate(
        wrapperType: String,
        propertyInfo: PropertyInfo
    ) -> PropertyWrapperSuggestion? {
        switch wrapperType {
        case "PathParameter":
            return validatePathParameter(propertyInfo)
        case "QueryParameter":
            return validateQueryParameter(propertyInfo)
        case "RequestBody":
            return validateRequestBody(propertyInfo)
        default:
            return nil
        }
    }

    /// PathParameter 검증
    private func validatePathParameter(_ info: PropertyInfo) -> PropertyWrapperSuggestion? {
        let placeholders = pathParser.extractPlaceholders(from: args.path)

        // 1. 옵셔널 검증
        if !info.isRequired, !args.optionalPathParameters.contains(info.name) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@PathParameter",
                reason: "PathParameter는 필수값이어야 합니다. 타입을 '\(info.type.replacingOccurrences(of: "?", with: ""))'로 변경하거나 경로를 '/.../{{\(info.name)?}'로 변경하세요"
            )
        }

        // 2. 경로 플레이스홀더와 일치하는지 확인
        if !placeholders.contains(info.name) {
            // 유사한 플레이스홀더 찾기
            if let similar = placeholders.first(where: { pathParser.areSimilar(info.name, $0) }) {
                return PropertyWrapperSuggestion(
                    propertyName: info.name,
                    suggestedWrapper: "@PathParameter(key: \"\(similar)\")",
                    reason: "경로에 {\(similar)}가 있습니다. @PathParameter(key: \"\(similar)\")를 사용하거나 프로퍼티 이름을 '\(similar)'로 변경하세요"
                )
            } else {
                let placeholderList = placeholders.isEmpty ? "" : "[\(placeholders.joined(separator: ", "))]"
                return PropertyWrapperSuggestion(
                    propertyName: info.name,
                    suggestedWrapper: "@PathParameter",
                    reason: placeholders.isEmpty
                        ? "경로에 {\(info.name)} 플레이스홀더가 없습니다. @QueryParameter 사용을 고려하세요"
                        : "경로의 플레이스홀더\(placeholderList)와 프로퍼티 이름이 일치하지 않습니다"
                )
            }
        }

        return nil
    }

    /// QueryParameter 검증
    private func validateQueryParameter(_ info: PropertyInfo) -> PropertyWrapperSuggestion? {
        // POST/PUT/PATCH에서 body 키워드가 있으면 RequestBody 제안
        if ["post", "put", "patch"].contains(args.method.lowercased()) {
            let bodyKeywords = ["body", "payload", "data", "request"]
            if bodyKeywords.contains(where: { info.name.lowercased().contains($0) }) {
                return PropertyWrapperSuggestion(
                    propertyName: info.name,
                    suggestedWrapper: "@RequestBody",
                    reason: "'\(info.name)'는 요청 바디로 보입니다. @RequestBody 사용을 고려하세요"
                )
            }
        }

        return nil
    }

    /// RequestBody 검증
    private func validateRequestBody(_ info: PropertyInfo) -> PropertyWrapperSuggestion? {
        // GET/DELETE에서는 RequestBody 사용 불가
        if ["get", "delete"].contains(args.method.lowercased()) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@QueryParameter",
                reason: "\(args.method.uppercased()) 메서드에서는 RequestBody를 사용할 수 없습니다"
            )
        }

        return nil
    }

    // MARK: - Suggestion

    /// 적절한 Property Wrapper 제안
    private func suggest(for info: PropertyInfo) -> PropertyWrapperSuggestion? {
        let lowercasedName = info.name.lowercased()

        // 1. HeaderField 제안
        if isHeaderRelated(propertyName: lowercasedName) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@HeaderField(key: .\(lowercasedName)) or @CustomHeader(\"\(info.name)\")",
                reason: "HTTP 헤더는 @HeaderField 또는 @CustomHeader를 사용하세요"
            )
        }

        // 2. PathParameter 제안
        if let matchedPlaceholder = findMatchingPathPlaceholder(propertyName: info.name) {
            let suggestion = matchedPlaceholder == info.name
                ? "@PathParameter"
                : "@PathParameter(key: \"\(matchedPlaceholder)\")"

            let reason = matchedPlaceholder == info.name
                ? "경로에 {\(matchedPlaceholder)}가 있으므로 @PathParameter를 사용하세요"
                : "경로에 {\(matchedPlaceholder)}가 있습니다. @PathParameter(key: \"\(matchedPlaceholder)\")를 사용하거나 프로퍼티 이름을 '\(matchedPlaceholder)'로 변경하세요"

            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: suggestion,
                reason: reason
            )
        }

        // 3. RequestBody 제안
        if isBodyRelated(propertyName: lowercasedName, httpMethod: args.method) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@RequestBody",
                reason: "요청 바디는 @RequestBody를 사용하세요"
            )
        }

        // 4. QueryParameter 제안 (GET 메서드의 옵셔널 프로퍼티)
        if args.method.lowercased() == "get", !info.isRequired {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@QueryParameter",
                reason: "GET 메서드의 파라미터는 @QueryParameter를 사용하세요 (optional이면 nil일 때 생략됨)"
            )
        }

        return nil
    }

    // MARK: - Helper Methods

    /// 경로에서 매칭되는 플레이스홀더 찾기
    private func findMatchingPathPlaceholder(propertyName: String) -> String? {
        let placeholders = pathParser.extractPlaceholders(from: args.path)

        // 1. 정확히 일치
        if placeholders.contains(propertyName) {
            return propertyName
        }

        // 2. 유사한 이름
        for placeholder in placeholders {
            if pathParser.areSimilar(propertyName, placeholder) {
                return placeholder
            }
        }

        return nil
    }

    /// 헤더 관련 프로퍼티인지 확인
    private func isHeaderRelated(propertyName: String) -> Bool {
        let headerKeywords = [
            "authorization", "auth", "token",
            "contenttype", "content",
            "useragent", "agent",
            "accept", "language",
            "cookie", "session",
            "apikey", "key",
            "bearer", "basic"
        ]

        return headerKeywords.contains { propertyName.contains($0) }
    }

    /// 요청 바디 관련 프로퍼티인지 확인
    /// - Parameters:
    ///   - propertyName: 검사할 프로퍼티 이름
    ///   - httpMethod: HTTP 메서드 (post, put, patch 등)
    /// - Returns: 바디 관련 프로퍼티인지 여부
    private func isBodyRelated(propertyName: String, httpMethod: String) -> Bool {
        let lowercasedName = propertyName.lowercased()
        
        // 바디 키워드 확인
        let bodyKeywords = ["body", "payload", "data", "request", "content"]
        let hasBodyKeyword = bodyKeywords.contains { lowercasedName.contains($0) }
        
        // 쿼리 파라미터로 자주 사용되는 이름 제외
        let queryKeywords = [
            "page", "size", "limit", "offset", 
            "sort", "filter", "search", "query",
            "order", "per", "from", "to"
        ]
        let isQueryParam = queryKeywords.contains { lowercasedName.contains($0) }
        
        // POST, PUT, PATCH 메서드 확인
        let isBodyMethod = ["post", "put", "patch"].contains(httpMethod.lowercased())
        
        // 바디 키워드가 있고, 쿼리 파라미터가 아니며, 바디를 사용하는 메서드인 경우
        return hasBodyKeyword && !isQueryParam && isBodyMethod
    }
}
