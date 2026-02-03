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

    // MARK: - Initializer
    
    /// PropertyInfo 생성자
    /// - Parameters:
    ///   - name: 프로퍼티 이름
    ///   - type: 프로퍼티 타입 (Optional 표시 포함 가능)
    ///   - wrapperType: Property Wrapper 타입 (예: "QueryParameter", "HeaderField")
    ///   - isRequired: 필수 값 여부. isOptional과 반대 개념.
    ///   - headerKey: HeaderField/CustomHeader의 헤더 키
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
}

// MARK: - Convenience Initializers

extension PropertyInfo {
    /// ResponseTestable 매크로 전용 편의 생성자
    /// - Parameters:
    ///   - name: 프로퍼티 이름
    ///   - type: 프로퍼티 타입
    ///   - isOptional: Optional 타입 여부
    public init(
        name: String,
        type: String,
        isOptional: Bool
    ) {
        self.init(
            name: name,
            type: type,
            wrapperType: nil,
            isRequired: !isOptional,
            headerKey: nil
        )
    }
}
