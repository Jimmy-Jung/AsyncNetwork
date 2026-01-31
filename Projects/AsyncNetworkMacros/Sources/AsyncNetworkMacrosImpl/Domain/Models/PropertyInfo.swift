public struct PropertyInfo {
    public let name: String
    public let type: String
    public let wrapperType: String?
    public let isRequired: Bool
    public let headerKey: String?

    public var isHeader: Bool {
        wrapperType == "HeaderField" || wrapperType == "CustomHeader"
    }

    public var isOptional: Bool {
        !isRequired
    }

    public init(
        name: String,
        type: String,
        wrapperType: String? = nil,
        isRequired: Bool = true,
        headerKey: String? = nil
    ) {
        self.name = name
        self.type = type
        self.wrapperType = wrapperType
        self.isRequired = isRequired
        self.headerKey = headerKey
    }

    public init(
        name: String,
        type: String,
        isOptional: Bool
    ) {
        self.name = name
        self.type = type
        wrapperType = nil
        isRequired = !isOptional
        headerKey = nil
    }
}
