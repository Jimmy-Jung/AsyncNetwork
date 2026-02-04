public protocol MacroValidator {
    func validate() throws
}

public struct APIRequestMacroValidator: MacroValidator {
    public let context: MacroContext
    public let validationLevel: ValidationLevel
    private let typeAnalyzer: TypeAnalyzer

    public init(
        context: MacroContext,
        validationLevel: ValidationLevel = .default
    ) {
        self.context = context
        self.validationLevel = validationLevel
        typeAnalyzer = TypeAnalyzer()
    }

    public func validate() throws {
        guard context.structDecl != nil else {
            throw MacroError.onlyApplicableToStruct
        }

        guard context.arguments != nil else {
            throw MacroError.missingArguments
        }
    }

    /// Phase 3: 검증 레벨에 따른 Property Wrapper 검증
    ///
    /// - Parameters:
    ///   - properties: 검증할 프로퍼티 목록
    ///   - pathParameters: Path에 정의된 Parameter 목록
    /// - Throws: ValidationLevel에 따른 에러 또는 경고
    public func validateProperties(
        _ properties: [PropertyInfo],
        pathParameters: Set<String>
    ) throws {
        switch validationLevel {
        case .strict:
            // 모든 검증을 강제 (에러)
            try validatePathParameters(properties, pathParameters: pathParameters, asError: true)
            try validatePropertyWrapperTypes(properties, asError: true)

        case .moderate:
            // 필수 검증만 에러, 나머지는 경고
            try validatePathParameters(properties, pathParameters: pathParameters, asError: false)
            try validatePropertyWrapperTypes(properties, asError: false)

        case .lenient:
            // 최소한의 검증만 (경고)
            break
        }
    }

    // MARK: - Private Validation Methods

    private func validatePathParameters(
        _ properties: [PropertyInfo],
        pathParameters: Set<String>,
        asError: Bool
    ) throws {
        let pathProps = properties.filter { $0.isPathParameter }

        for prop in pathProps where !pathParameters.contains(prop.name) {
            let error = MacroError.pathParameterNotFound(
                parameterName: prop.name,
                availableParameters: Array(pathParameters)
            )
            if asError {
                throw error
            }
            // 경고는 context.diagnose()를 통해 처리 (필요 시 구현)
        }
    }

    private func validatePropertyWrapperTypes(
        _ properties: [PropertyInfo],
        asError: Bool
    ) throws {
        for prop in properties {
            if let wrapperType = prop.wrapperType {
                let isValidType = validateType(
                    propType: prop.type,
                    forWrapper: wrapperType
                )

                if !isValidType {
                    let expectedType = expectedType(for: wrapperType)
                    let error = MacroError.propertyWrapperTypeMismatch(
                        propertyName: prop.name,
                        wrapperType: wrapperType,
                        expectedType: expectedType
                    )

                    if asError {
                        throw error
                    }
                    // 경고는 context.diagnose()를 통해 처리 (필요 시 구현)
                }
            }
        }
    }

    /// Phase 4: TypeAnalyzer를 활용한 타입 검증
    ///
    /// Swift.String, String?, Optional<String> 등 다양한 표기법을 허용합니다.
    private func validateType(propType: String, forWrapper wrapper: String) -> Bool {
        switch wrapper {
        case "QueryParameter":
            // String, Int, Bool, Double, Float 및 Optional 허용
            let allowedTypes = ["String", "Int", "Bool", "Double", "Float"]
            return typeAnalyzer.isCompatible(givenType: propType, expectedTypes: allowedTypes)

        case "PathParameter":
            // String 타입만 허용 (Optional도 허용)
            return typeAnalyzer.isStringCompatible(propType)

        case "RequestBody":
            // Encodable 준수 여부는 컴파일 타임에 체크되므로 여기서는 통과
            return true

        case "HeaderField", "CustomHeader":
            // String 타입만 허용 (Optional도 허용)
            return typeAnalyzer.isStringCompatible(propType)

        default:
            return true
        }
    }

    private func expectedType(for wrapper: String) -> String {
        switch wrapper {
        case "QueryParameter":
            return "String, Int, Bool, Double, Float 또는 이들의 Optional (String?, Swift.String, Optional<Int> 등 모두 허용)"
        case "PathParameter":
            return "String 또는 Optional<String> (Swift.String, String? 등 모두 허용)"
        case "RequestBody":
            return "Encodable 준수 타입"
        case "HeaderField", "CustomHeader":
            return "String 또는 Optional<String> (Swift.String, String? 등 모두 허용)"
        default:
            return "Any"
        }
    }
}
