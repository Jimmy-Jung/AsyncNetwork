struct TestableArguments {
    let scenarios: [String]
    let errorExamples: [String: String]
    let includeRetryTests: Bool
    let includePerformanceTests: Bool

    init(
        scenarios: [String] = [],
        errorExamples: [String: String] = [:],
        includeRetryTests: Bool = true,
        includePerformanceTests: Bool = false
    ) {
        self.scenarios = scenarios
        self.errorExamples = errorExamples
        self.includeRetryTests = includeRetryTests
        self.includePerformanceTests = includePerformanceTests
    }
}
