import Foundation

/// 응답 처리 단계를 나타내는 프로토콜
///
/// **사용 예시:**
/// ```swift
/// let processor = ResponseProcessor(
///     steps: [
///         StatusCodeValidationStep(),
///         CustomValidationStep(),
///         LoggingStep()
///     ]
/// )
/// ```
public protocol ResponseProcessorStep: Sendable {
    func process(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError>
}

public struct StatusCodeValidationStep: ResponseProcessorStep {
    private let validator: StatusCodeValidator

    public init(validator: StatusCodeValidator = .default) {
        self.validator = validator
    }

    public func process(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError> {
        do {
            let validatedResponse = try validator.validate(response)
            return .success(validatedResponse)
        } catch {
            return .failure(ErrorMapper.default.mapError(error, request: request))
        }
    }
}
