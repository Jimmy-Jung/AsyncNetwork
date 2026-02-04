/// @APIRequest 매크로의 파싱된 인자들
public struct MacroArguments {
    // MARK: - Required Arguments

    public let responseType: String
    public let baseURL: String
    public let isBaseURLLiteral: Bool
    public let path: String
    public let method: String

    // MARK: - Optional Arguments (Phase 3)

    /// 검증 레벨 (기본값: .strict)
    public let validationLevel: ValidationLevel

    /// 동적 메서드 지원 여부
    public let isDynamicMethod: Bool

    /// 동적 메서드 프로퍼티 이름 (예: "httpMethod")
    public let dynamicMethodProperty: String?

    // MARK: - Parsed Data

    public let optionalPathParameters: Set<String>

    public init(
        responseType: String,
        baseURL: String,
        isBaseURLLiteral: Bool = true,
        path: String,
        method: String,
        validationLevel: ValidationLevel = .default,
        isDynamicMethod: Bool = false,
        dynamicMethodProperty: String? = nil,
        optionalPathParameters: Set<String> = []
    ) {
        self.responseType = responseType
        self.baseURL = baseURL
        self.isBaseURLLiteral = isBaseURLLiteral
        self.path = path
        self.method = method
        self.validationLevel = validationLevel
        self.isDynamicMethod = isDynamicMethod
        self.dynamicMethodProperty = dynamicMethodProperty
        self.optionalPathParameters = optionalPathParameters
    }
}
