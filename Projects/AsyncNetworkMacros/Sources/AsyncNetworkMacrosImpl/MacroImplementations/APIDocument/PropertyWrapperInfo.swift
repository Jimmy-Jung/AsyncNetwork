public struct PropertyWrapperInfo {
    public let name: String
    public let type: String
    public let wrapperType: String
    public let headerKey: String?
    public let defaultValue: String?

    public init(
        name: String,
        type: String,
        wrapperType: String,
        headerKey: String? = nil,
        defaultValue: String? = nil
    ) {
        self.name = name
        self.type = type
        self.wrapperType = wrapperType
        self.headerKey = headerKey
        self.defaultValue = defaultValue
    }
}
