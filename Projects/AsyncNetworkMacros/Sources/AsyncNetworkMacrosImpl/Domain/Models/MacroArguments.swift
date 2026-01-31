public struct MacroArguments {
    public let responseType: String
    public let baseURL: String
    public let isBaseURLLiteral: Bool
    public let path: String
    public let method: String
    public let optionalPathParameters: Set<String>

    public init(
        responseType: String,
        baseURL: String,
        isBaseURLLiteral: Bool = true,
        path: String,
        method: String,
        optionalPathParameters: Set<String> = []
    ) {
        self.responseType = responseType
        self.baseURL = baseURL
        self.isBaseURLLiteral = isBaseURLLiteral
        self.path = path
        self.method = method
        self.optionalPathParameters = optionalPathParameters
    }
}
