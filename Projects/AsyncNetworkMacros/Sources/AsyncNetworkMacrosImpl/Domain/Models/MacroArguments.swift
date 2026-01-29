public struct MacroArguments {
    public let responseType: String
    public let title: String
    public let description: String
    public let baseURL: String
    public let isBaseURLLiteral: Bool
    public let path: String
    public let method: String
    public let tags: [String]
    public let optionalPathParameters: Set<String>

    public let testScenarios: [String]
    public let errorExamples: [String: String]
    public let includeRetryTests: Bool
    public let includePerformanceTests: Bool

    public init(
        responseType: String,
        title: String = "",
        description: String = "",
        baseURL: String,
        isBaseURLLiteral: Bool = true,
        path: String,
        method: String,
        tags: [String] = [],
        optionalPathParameters: Set<String> = [],
        testScenarios: [String] = [],
        errorExamples: [String: String] = [:],
        includeRetryTests: Bool = true,
        includePerformanceTests: Bool = false
    ) {
        self.responseType = responseType
        self.title = title
        self.description = description
        self.baseURL = baseURL
        self.isBaseURLLiteral = isBaseURLLiteral
        self.path = path
        self.method = method
        self.tags = tags
        self.optionalPathParameters = optionalPathParameters
        self.testScenarios = testScenarios
        self.errorExamples = errorExamples
        self.includeRetryTests = includeRetryTests
        self.includePerformanceTests = includePerformanceTests
    }
}
