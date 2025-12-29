//
//  AsyncNetworkFactoryTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetwork
import Foundation
import Testing

// MARK: - NetworkKitTests

struct NetworkKitTests {
    @Test("NetworkKit 버전 확인")
    func versionCheck() {
        #expect(AsyncNetwork.version == "1.0.0")
    }
}

// MARK: - NetworkKitFactoryTests

struct NetworkKitFactoryTests {
    @Test("createNetworkService 기본 설정")
    func createNetworkServiceWithDefaults() {
        // Given & When
        let service = AsyncNetwork.createNetworkService()

        // Then
        #expect(service is NetworkService)
    }

    @Test("createNetworkService 커스텀 interceptors")
    func createNetworkServiceWithCustomInterceptors() {
        // Given
        struct CustomInterceptor: RequestInterceptor {}

        // When
        let service = AsyncNetwork.createNetworkService(
            interceptors: [CustomInterceptor()]
        )

        // Then
        #expect(service is NetworkService)
    }

    @Test("createNetworkService 빈 interceptors")
    func createNetworkServiceWithEmptyInterceptors() {
        // Given & When
        let service = AsyncNetwork.createNetworkService(interceptors: [])

        // Then
        #expect(service is NetworkService)
    }

    @Test("createNetworkService 커스텀 configuration")
    func createNetworkServiceWithCustomConfiguration() {
        // Given
        let configuration = NetworkConfiguration(
            maxRetries: 5,
            retryDelay: 2.0,
            timeout: 60.0,
            enableLogging: false
        )

        // When
        let service = AsyncNetwork.createNetworkService(
            configuration: configuration
        )

        // Then
        #expect(service is NetworkService)
    }

    @Test("createNetworkService 다양한 기본 설정", arguments: [
        NetworkConfiguration.default,
        NetworkConfiguration.development,
        NetworkConfiguration.test,
        NetworkConfiguration.stable,
        NetworkConfiguration.fast
    ])
    func createNetworkServiceWithVariousConfigurations(configuration: NetworkConfiguration) {
        // Given & When
        let service = AsyncNetwork.createNetworkService(configuration: configuration)

        // Then
        #expect(service is NetworkService)
    }

    // MARK: - Test Helper Factory Tests

    #if DEBUG
        @Test("createTestNetworkService 기본 설정")
        func createTestNetworkServiceWithDefaults() {
            // Given & When
            let service = AsyncNetwork.createTestNetworkService()

            // Then
            #expect(service is NetworkService)
        }

        @Test("createTestNetworkService 커스텀 HTTPClient")
        func createTestNetworkServiceWithCustomHTTPClient() {
            // Given
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: configuration)
            let httpClient = HTTPClient(session: session)

            // When
            let service = AsyncNetwork.createTestNetworkService(httpClient: httpClient)

            // Then
            #expect(service is NetworkService)
        }

        @Test("createTestNetworkService 커스텀 RetryPolicy")
        func createTestNetworkServiceWithCustomRetryPolicy() {
            // Given
            let retryPolicy = RetryPolicy.none

            // When
            let service = AsyncNetwork.createTestNetworkService(retryPolicy: retryPolicy)

            // Then
            #expect(service is NetworkService)
        }

        @Test("createTestNetworkService 커스텀 ResponseProcessor")
        func createTestNetworkServiceWithCustomResponseProcessor() {
            // Given
            let responseProcessor = ResponseProcessor()

            // When
            let service = AsyncNetwork.createTestNetworkService(
                responseProcessor: responseProcessor
            )

            // Then
            #expect(service is NetworkService)
        }

        @Test("createTestNetworkService 커스텀 DataResponseProcessor")
        func createTestNetworkServiceWithCustomDataResponseProcessor() {
            // Given
            let dataResponseProcessor = DataResponseProcessor()

            // When
            let service = AsyncNetwork.createTestNetworkService(
                dataResponseProcessor: dataResponseProcessor
            )

            // Then
            #expect(service is NetworkService)
        }

        @Test("createTestNetworkService 커스텀 interceptors")
        func createTestNetworkServiceWithCustomInterceptors() {
            // Given
            struct TestInterceptor: RequestInterceptor {}

            // When
            let service = AsyncNetwork.createTestNetworkService(
                interceptors: [TestInterceptor()]
            )

            // Then
            #expect(service is NetworkService)
        }

        @Test("createTestNetworkService 모든 커스텀 파라미터")
        func createTestNetworkServiceWithAllCustomParameters() {
            // Given
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: configuration)
            let httpClient = HTTPClient(session: session)
            let retryPolicy = RetryPolicy.aggressive
            let responseProcessor = ResponseProcessor()
            let dataResponseProcessor = DataResponseProcessor()

            struct TestInterceptor: RequestInterceptor {}

            // When
            let service = AsyncNetwork.createTestNetworkService(
                httpClient: httpClient,
                retryPolicy: retryPolicy,
                configuration: .test,
                responseProcessor: responseProcessor,
                dataResponseProcessor: dataResponseProcessor,
                interceptors: [TestInterceptor()]
            )

            // Then
            #expect(service is NetworkService)
        }
    #endif
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
