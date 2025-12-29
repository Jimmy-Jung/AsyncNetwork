//
//  ResponseProcessorStep.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - ResponseProcessorStep

/// 응답 처리 단계를 나타내는 프로토콜
///
/// **설계 원칙:**
/// - 각 단계는 독립적으로 동작
/// - 배열로 조합하여 순차 처리
/// - 의존성 주입으로 유연한 구성
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
    /// 응답 처리
    /// - Parameters:
    ///   - response: 처리할 HTTP 응답
    ///   - request: 원본 API 요청
    /// - Returns: 처리 결과 (성공 시 다음 단계로 전달, 실패 시 에러)
    func process(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError>
}

// MARK: - StatusCodeValidationStep

/// HTTP 상태 코드 검증 단계
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
