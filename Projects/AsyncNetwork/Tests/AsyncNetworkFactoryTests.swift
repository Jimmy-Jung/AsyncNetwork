//
//  AsyncNetworkFactoryTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - NetworkServiceFactoryTests

struct NetworkServiceFactoryTests {
    @Test("NetworkService 기본 생성")
    func createNetworkServiceWithDefaults() {
        // Given & When
        let service = NetworkService()

        // Then - NetworkService가 성공적으로 생성됨
        _ = service
    }

    @Test("NetworkService 커스텀 interceptors")
    func createNetworkServiceWithCustomInterceptors() {
        // Given
        struct CustomInterceptor: RequestInterceptor {}
        let plugins: [any RequestInterceptor] = [CustomInterceptor()]

        // When
        let service = NetworkService(plugins: plugins)

        // Then - NetworkService가 성공적으로 생성됨
        _ = service
    }

    @Test("NetworkService 빈 interceptors")
    func createNetworkServiceWithEmptyInterceptors() {
        // Given & When
        let service = NetworkService(plugins: [])

        // Then - NetworkService가 성공적으로 생성됨
        _ = service
    }

    @Test("NetworkService 커스텀 configuration")
    func createNetworkServiceWithCustomConfiguration() {
        // Given
        let configuration = NetworkConfiguration(
            maxRetries: 5,
            retryDelay: 2.0,
            timeout: 60.0,
            enableLogging: false
        )

        // When
        let service = NetworkService(configuration: configuration)

        // Then - NetworkService가 성공적으로 생성됨
        _ = service
    }

    @Test("NetworkService 다양한 configuration", arguments: [
        NetworkConfiguration.default,
        NetworkConfiguration.development,
        NetworkConfiguration.test,
        NetworkConfiguration.stable,
        NetworkConfiguration.fast
    ])
    func createNetworkServiceWithVariousConfigurations(configuration: NetworkConfiguration) {
        // Given & When
        let service = NetworkService(configuration: configuration)

        // Then - NetworkService가 성공적으로 생성됨
        _ = service
    }

    @Test("NetworkService 완전한 커스텀 초기화")
    func createNetworkServiceWithFullCustomization() {
        // Given
        let httpClient = HTTPClient(session: .shared)
        let retryPolicy = RetryPolicy.aggressive
        let responseProcessor = ResponseProcessor()
        let dataResponseProcessor = DataResponseProcessor()
        struct TestInterceptor: RequestInterceptor {}
        let interceptors: [any RequestInterceptor] = [TestInterceptor()]

        // When
        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: retryPolicy,
            responseProcessor: responseProcessor,
            dataResponseProcessor: dataResponseProcessor,
            interceptors: interceptors
        )

        // Then - NetworkService가 성공적으로 생성됨
        _ = service
    }
}

// MARK: - ResponseProcessorStep Tests

struct ResponseProcessorStepTests {
    @Test("StatusCodeValidationStep 성공 응답 처리")
    func statusCodeValidationStepSuccess() {
        // Given
        let step = StatusCodeValidationStep()
        let response = HTTPResponse(statusCode: 200, data: Data())

        // When
        let result = step.process(response, request: nil)

        // Then
        switch result {
        case let .success(processedResponse):
            #expect(processedResponse.statusCode == 200)
        case .failure:
            Issue.record("성공 응답이 실패로 처리됨")
        }
    }

    @Test("StatusCodeValidationStep 클라이언트 에러 처리")
    func statusCodeValidationStepClientError() {
        // Given
        let step = StatusCodeValidationStep()
        let response = HTTPResponse(statusCode: 400, data: Data())

        // When
        let result = step.process(response, request: nil)

        // Then
        switch result {
        case .success:
            Issue.record("클라이언트 에러가 성공으로 처리됨")
        case let .failure(error):
            if case let .httpError(statusError) = error {
                #expect(statusError.statusCode == 400)
            } else {
                Issue.record("예상치 못한 에러 타입: \(error)")
            }
        }
    }

    @Test("StatusCodeValidationStep 서버 에러 처리")
    func statusCodeValidationStepServerError() {
        // Given
        let step = StatusCodeValidationStep()
        let response = HTTPResponse(statusCode: 500, data: Data())

        // When
        let result = step.process(response, request: nil)

        // Then
        switch result {
        case .success:
            Issue.record("서버 에러가 성공으로 처리됨")
        case let .failure(error):
            if case let .httpError(statusError) = error {
                #expect(statusError.statusCode == 500)
            } else {
                Issue.record("예상치 못한 에러 타입: \(error)")
            }
        }
    }

    @Test("StatusCodeValidationStep 커스텀 validator")
    func statusCodeValidationStepCustomValidator() {
        // Given
        let customValidator = StatusCodeValidator.lenient // 200-399 허용
        let step = StatusCodeValidationStep(validator: customValidator)
        let response = HTTPResponse(statusCode: 302, data: Data())

        // When
        let result = step.process(response, request: nil)

        // Then
        switch result {
        case let .success(processedResponse):
            #expect(processedResponse.statusCode == 302)
        case .failure:
            Issue.record("302 응답이 lenient validator에서 실패로 처리됨")
        }
    }

    @Test("StatusCodeValidationStep 다양한 성공 코드", arguments: [200, 201, 202, 204])
    func statusCodeValidationStepVariousSuccessCodes(statusCode: Int) {
        // Given
        let step = StatusCodeValidationStep()
        let response = HTTPResponse(statusCode: statusCode, data: Data())

        // When
        let result = step.process(response, request: nil)

        // Then
        switch result {
        case let .success(processedResponse):
            #expect(processedResponse.statusCode == statusCode)
        case .failure:
            Issue.record("\(statusCode) 응답이 실패로 처리됨")
        }
    }
}
