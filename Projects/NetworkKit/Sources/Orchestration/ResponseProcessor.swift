//
//  ResponseProcessor.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - ResponseProcessing Protocol

/// 응답 처리를 담당하는 프로토콜 (Decodable 결과)
public protocol ResponseProcessing: Sendable {
    /// 응답 처리 및 디코딩
    func process<T: Decodable>(
        result: Result<HTTPResponse, Error>,
        decodeType: T.Type,
        request: (any APIRequest)?
    ) -> Result<T, NetworkError>
}

// MARK: - DataResponseProcessing Protocol

/// 응답 처리를 담당하는 프로토콜 (Raw Data 결과)
public protocol DataResponseProcessing: Sendable {
    /// 응답 처리 (디코딩 없음)
    func process(
        result: Result<HTTPResponse, Error>,
        request: (any APIRequest)?
    ) -> Result<Data, NetworkError>
}

// MARK: - ResponseProcessor

/// 표준 응답 처리기 (디코딩 지원)
public struct ResponseProcessor: ResponseProcessing {
    private let steps: [any ResponseProcessorStep]
    private let decoder: ResponseDecoder
    private let errorMapper: ErrorMapper

    public init(
        steps: [any ResponseProcessorStep] = [StatusCodeValidationStep()],
        decoder: ResponseDecoder = .default,
        errorMapper: ErrorMapper = .default
    ) {
        self.steps = steps
        self.decoder = decoder
        self.errorMapper = errorMapper
    }

    public func process<T: Decodable>(
        result: Result<HTTPResponse, Error>,
        decodeType _: T.Type,
        request: (any APIRequest)?
    ) -> Result<T, NetworkError> {
        // 1. 에러 매핑
        let mappedResult = result.mapError { errorMapper.mapError($0, request: request) }

        // 2. 각 단계 실행
        var currentResult = mappedResult
        for step in steps {
            currentResult = currentResult.flatMap { response in
                step.process(response, request: request)
            }

            if case .failure = currentResult { break }
        }

        // 3. 디코딩
        return currentResult.flatMap { response in
            do {
                let decoded = try decoder.decode(response, to: T.self)
                return .success(decoded)
            } catch {
                return .failure(errorMapper.mapError(error, request: request))
            }
        }
    }
}

// MARK: - DataResponseProcessor

/// 데이터 응답 처리기 (디코딩 없이 Data 반환)
public struct DataResponseProcessor: DataResponseProcessing {
    private let steps: [any ResponseProcessorStep]
    private let errorMapper: ErrorMapper

    public init(
        steps: [any ResponseProcessorStep] = [StatusCodeValidationStep()],
        errorMapper: ErrorMapper = .default
    ) {
        self.steps = steps
        self.errorMapper = errorMapper
    }

    public func process(
        result: Result<HTTPResponse, Error>,
        request: (any APIRequest)?
    ) -> Result<Data, NetworkError> {
        // 1. 에러 매핑
        let mappedResult = result.mapError { errorMapper.mapError($0, request: request) }

        // 2. 각 단계 실행
        var currentResult = mappedResult
        for step in steps {
            currentResult = currentResult.flatMap { response in
                step.process(response, request: request)
            }

            if case .failure = currentResult { break }
        }

        // 3. Raw 데이터 추출
        return currentResult.map { $0.data }
    }
}
