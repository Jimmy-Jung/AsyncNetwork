import SwiftSyntax

public struct PropertyWrapperValidator {
    public let context: MacroContext
    public let args: MacroArguments
    public let pathParser: PathParser

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

            if let wrapperType = propertyInfo.wrapperType {
                if let suggestion = validate(wrapperType: wrapperType, propertyInfo: propertyInfo) {
                    suggestions.append(suggestion)
                }
            } else {
                if let suggestion = suggest(for: propertyInfo) {
                    suggestions.append(suggestion)
                }
            }
        }

        return suggestions
    }

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

    private func validatePathParameter(_ info: PropertyInfo) -> PropertyWrapperSuggestion? {
        let placeholders = pathParser.extractPlaceholders(from: args.path)

        if !info.isRequired, !args.optionalPathParameters.contains(info.name) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@PathParameter",
                reason:
                    """
                    PathParameter는 필수값이어야 합니다. \
                    타입을 '\(info.type.replacingOccurrences(of: "?", with: ""))'로 변경하거나 \
                    경로를 '/.../{{\(info.name)?}'로 변경하세요
                    """
            )
        }

        if !placeholders.contains(info.name) {
            if let similar = placeholders.first(where: { pathParser.areSimilar(info.name, $0) }) {
                return PropertyWrapperSuggestion(
                    propertyName: info.name,
                    suggestedWrapper: "@PathParameter(key: \"\(similar)\")",
                    reason:
                        """
                        경로에 {\(similar)}가 있습니다. \
                        @PathParameter(key: \"\(similar)\")를 사용하거나 \
                        프로퍼티 이름을 '\(similar)'로 변경하세요
                        """
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

    private func validateQueryParameter(_ info: PropertyInfo) -> PropertyWrapperSuggestion? {
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

    private func validateRequestBody(_ info: PropertyInfo) -> PropertyWrapperSuggestion? {
        if ["get", "delete"].contains(args.method.lowercased()) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@QueryParameter",
                reason: "\(args.method.uppercased()) 메서드에서는 RequestBody를 사용할 수 없습니다"
            )
        }

        return nil
    }

    private func suggest(for info: PropertyInfo) -> PropertyWrapperSuggestion? {
        let lowercasedName = info.name.lowercased()

        if isHeaderRelated(propertyName: lowercasedName) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@HeaderField(key: .\(lowercasedName)) or @CustomHeader(\"\(info.name)\")",
                reason: "HTTP 헤더는 @HeaderField 또는 @CustomHeader를 사용하세요"
            )
        }

        if let matchedPlaceholder = findMatchingPathPlaceholder(propertyName: info.name) {
            let suggestion = matchedPlaceholder == info.name
                ? "@PathParameter"
                : "@PathParameter(key: \"\(matchedPlaceholder)\")"

            let reason = matchedPlaceholder == info.name
                ? "경로에 {\(matchedPlaceholder)}가 있으므로 @PathParameter를 사용하세요"
                : """
                경로에 {\(matchedPlaceholder)}가 있습니다. \
                @PathParameter(key: \"\(matchedPlaceholder)\")를 사용하거나 \
                프로퍼티 이름을 '\(matchedPlaceholder)'로 변경하세요
                """

            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: suggestion,
                reason: reason
            )
        }

        if isBodyRelated(propertyName: lowercasedName, httpMethod: args.method) {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@RequestBody",
                reason: "요청 바디는 @RequestBody를 사용하세요"
            )
        }

        if args.method.lowercased() == "get", !info.isRequired {
            return PropertyWrapperSuggestion(
                propertyName: info.name,
                suggestedWrapper: "@QueryParameter",
                reason: "GET 메서드의 파라미터는 @QueryParameter를 사용하세요 (optional이면 nil일 때 생략됨)"
            )
        }

        return nil
    }

    private func findMatchingPathPlaceholder(propertyName: String) -> String? {
        let placeholders = pathParser.extractPlaceholders(from: args.path)

        if placeholders.contains(propertyName) {
            return propertyName
        }

        for placeholder in placeholders where pathParser.areSimilar(propertyName, placeholder) {
            return placeholder
        }

        return nil
    }

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

    private func isBodyRelated(propertyName: String, httpMethod: String) -> Bool {
        let lowercasedName = propertyName.lowercased()

        let bodyKeywords = ["body", "payload", "data", "request", "content"]
        let hasBodyKeyword = bodyKeywords.contains { lowercasedName.contains($0) }

        let queryKeywords = [
            "page", "size", "limit", "offset",
            "sort", "filter", "search", "query",
            "order", "per", "from", "to"
        ]
        let isQueryParam = queryKeywords.contains { lowercasedName.contains($0) }

        let isBodyMethod = ["post", "put", "patch"].contains(httpMethod.lowercased())

        return hasBodyKeyword && !isQueryParam && isBodyMethod
    }
}
