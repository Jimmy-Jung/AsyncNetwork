public struct DocumentArguments {
    public let title: String
    public let description: String
    public let tags: [String]

    public init(
        title: String,
        description: String,
        tags: [String]
    ) {
        self.title = title
        self.description = description
        self.tags = tags
    }
}
