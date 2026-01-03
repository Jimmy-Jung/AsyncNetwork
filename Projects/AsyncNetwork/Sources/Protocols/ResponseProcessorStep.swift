//
//  ResponseProcessorStep.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// 응답 처리 단계를 나타내는 프로토콜
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
