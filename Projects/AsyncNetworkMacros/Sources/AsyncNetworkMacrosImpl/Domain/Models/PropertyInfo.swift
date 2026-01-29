public struct PropertyInfo {
    public let name: String
    public let type: String
    public let wrapperType: String?
    public let isRequired: Bool
    public let headerKey: String?
    public let defaultValue: String?

    public var isHeader: Bool {
        wrapperType == "HeaderField" || wrapperType == "CustomHeader"
    }

    public var isPathParameter: Bool {
        wrapperType == "PathParameter"
    }

    public var isQueryParameter: Bool {
        wrapperType == "QueryParameter"
    }

    public var isRequestBody: Bool {
        wrapperType == "RequestBody"
    }

    public var isOptional: Bool {
        !isRequired
    }

    public init(
        name: String,
        type: String,
        wrapperType: String? = nil,
        isRequired: Bool = true,
        headerKey: String? = nil,
        defaultValue: String? = nil
    ) {
        self.name = name
        self.type = type
        self.wrapperType = wrapperType
        self.isRequired = isRequired
        self.headerKey = headerKey
        self.defaultValue = defaultValue
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
        defaultValue = nil
    }
}
