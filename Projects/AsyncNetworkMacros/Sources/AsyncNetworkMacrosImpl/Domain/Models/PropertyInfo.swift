//
//  PropertyInfo.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

/// Property Wrapper 정보
public struct PropertyInfo {
    /// 프로퍼티 이름
    public let name: String

    /// 프로퍼티 타입 (예: "Int", "String?")
    public let type: String

    /// Property Wrapper 타입 (예: "PathParameter", "QueryParameter")
    public let wrapperType: String?

    /// 필수 여부 (옵셔널이 아니면 true)
    public let isRequired: Bool

    /// 헤더 키 (HeaderField, CustomHeader용)
    public let headerKey: String?

    /// 기본값
    public let defaultValue: String?

    // MARK: - Convenience

    /// HeaderField 또는 CustomHeader 여부
    public var isHeader: Bool {
        wrapperType == "HeaderField" || wrapperType == "CustomHeader"
    }

    /// PathParameter 여부
    public var isPathParameter: Bool {
        wrapperType == "PathParameter"
    }

    /// QueryParameter 여부
    public var isQueryParameter: Bool {
        wrapperType == "QueryParameter"
    }

    /// RequestBody 여부
    public var isRequestBody: Bool {
        wrapperType == "RequestBody"
    }

    /// 옵셔널 여부 (isRequired의 반대)
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

    /// 간단한 초기화자 (isOptional 기반)
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
