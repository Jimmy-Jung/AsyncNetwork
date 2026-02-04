import Foundation

/// 타입 문자열 분석 및 호환성 검사 유틸리티
///
/// Swift 타입 문자열을 파싱하고 정규화하여 타입 호환성을 검증합니다.
/// Optional 언래핑, 모듈 한정자 제거, 화이트스페이스 정규화 등을 지원합니다.
public struct TypeAnalyzer {
    public init() {}

    // MARK: - Optional 분석

    /// Optional 타입을 언래핑하여 내부 타입을 반환합니다
    ///
    /// - Parameter typeString: 타입 문자열 (예: "String?", "Optional<Int>")
    /// - Returns: 언래핑된 타입 문자열. Optional이 아니면 nil 반환
    ///
    /// - Example:
    ///   ```swift
    ///   unwrapOptional("String?") // "String"
    ///   unwrapOptional("Optional<Int>") // "Int"
    ///   unwrapOptional("String") // nil
    ///   ```
    public func unwrapOptional(_ typeString: String) -> String? {
        let normalized = typeString.trimmingCharacters(in: .whitespaces)

        // String? 형태
        if normalized.hasSuffix("?") {
            return String(normalized.dropLast())
        }

        // Optional<T> 형태
        if normalized.hasPrefix("Optional<"), normalized.hasSuffix(">") {
            let startIndex = normalized.index(normalized.startIndex, offsetBy: 9) // "Optional<".count
            let endIndex = normalized.index(before: normalized.endIndex)
            return String(normalized[startIndex ..< endIndex])
        }

        return nil
    }

    /// 타입이 Optional인지 확인합니다
    ///
    /// - Parameter typeString: 타입 문자열
    /// - Returns: Optional 타입이면 true
    public func isOptional(_ typeString: String) -> Bool {
        unwrapOptional(typeString) != nil
    }

    // MARK: - 타입 정규화

    /// 타입 이름을 정규화합니다
    ///
    /// 화이트스페이스 제거, 모듈 한정자 제거, Optional 언래핑 등을 수행합니다.
    ///
    /// - Parameter typeString: 원본 타입 문자열
    /// - Returns: 정규화된 타입 문자열
    ///
    /// - Example:
    ///   ```swift
    ///   normalizeTypeName("Swift.String?") // "String"
    ///   normalizeTypeName("  Optional<Int>  ") // "Int"
    ///   normalizeTypeName("Foundation.URL") // "URL"
    ///   ```
    public func normalizeTypeName(_ typeString: String) -> String {
        var normalized = typeString.trimmingCharacters(in: .whitespaces)

        // Optional 언래핑
        if let unwrapped = unwrapOptional(normalized) {
            normalized = unwrapped
        }

        // 모듈 한정자 제거 (Swift., Foundation. 등)
        if let lastDot = normalized.lastIndex(of: ".") {
            normalized = String(normalized[normalized.index(after: lastDot)...])
        }

        // 제네릭 타입 내부 정규화 (재귀적으로)
        normalized = normalizeGenericType(normalized)

        return normalized
    }

    /// 제네릭 타입 내부의 화이트스페이스를 정규화합니다
    private func normalizeGenericType(_ typeString: String) -> String {
        // Array<T>, Dictionary<K, V> 등의 제네릭 타입 처리
        guard typeString.contains("<"), typeString.contains(">") else {
            return typeString
        }

        // 간단한 화이트스페이스 제거
        return typeString.replacingOccurrences(of: " ", with: "")
    }

    // MARK: - 타입 호환성 검사

    /// 주어진 타입이 예상되는 타입 중 하나와 호환되는지 확인합니다
    ///
    /// Optional 여부와 모듈 한정자를 무시하고 기본 타입 이름만 비교합니다.
    ///
    /// - Parameters:
    ///   - givenType: 검사할 타입 문자열
    ///   - expectedTypes: 허용되는 타입 목록
    /// - Returns: 호환 가능하면 true
    ///
    /// - Example:
    ///   ```swift
    ///   isCompatible(givenType: "String?", expectedTypes: ["String"])  // true
    ///   isCompatible(givenType: "Swift.String", expectedTypes: ["String"])  // true
    ///   isCompatible(givenType: "Optional<Int>", expectedTypes: ["Int", "Double"])  // true
    ///   ```
    public func isCompatible(givenType: String, expectedTypes: [String]) -> Bool {
        let normalized = normalizeTypeName(givenType)

        for expectedType in expectedTypes {
            let normalizedExpected = normalizeTypeName(expectedType)
            if normalized == normalizedExpected {
                return true
            }
        }

        return false
    }

    /// 두 타입이 동일한지 확인합니다 (정규화 후 비교)
    ///
    /// - Parameters:
    ///   - type1: 첫 번째 타입
    ///   - type2: 두 번째 타입
    /// - Returns: 정규화 후 동일하면 true
    public func areEqual(_ type1: String, _ type2: String) -> Bool {
        normalizeTypeName(type1) == normalizeTypeName(type2)
    }

    // MARK: - 기본 타입 검사

    /// Swift 기본 타입인지 확인합니다
    ///
    /// - Parameter typeString: 타입 문자열
    /// - Returns: Swift 기본 타입이면 true
    public func isSwiftPrimitiveType(_ typeString: String) -> Bool {
        let primitives: Set<String> = [
            "String", "Int", "Double", "Float", "Bool",
            "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Character", "Array", "Dictionary", "Set"
        ]

        let normalized = normalizeTypeName(typeString)
        return primitives.contains(normalized)
    }

    /// String 타입과 호환되는지 확인합니다
    ///
    /// `String`, `String?`, `Optional<String>`, `Swift.String` 등 모두 허용
    ///
    /// - Parameter typeString: 타입 문자열
    /// - Returns: String 호환 타입이면 true
    public func isStringCompatible(_ typeString: String) -> Bool {
        isCompatible(givenType: typeString, expectedTypes: ["String"])
    }

    /// 숫자 타입과 호환되는지 확인합니다
    ///
    /// - Parameter typeString: 타입 문자열
    /// - Returns: 숫자 타입이면 true
    public func isNumericCompatible(_ typeString: String) -> Bool {
        let numericTypes = [
            "Int", "Double", "Float",
            "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64"
        ]
        return isCompatible(givenType: typeString, expectedTypes: numericTypes)
    }
}
