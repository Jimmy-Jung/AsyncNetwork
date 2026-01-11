//
//  ErrorSimulatorTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

@testable import AsyncNetworkSampleApp
import Testing

/// ErrorSimulator 도메인 모델 테스트
@Suite("ErrorSimulator 도메인 모델")
struct ErrorSimulatorTests {
    // MARK: - SimulatedErrorType Tests

    @Test("SimulatedErrorType은 모든 에러 타입을 제공한다")
    func simulatedErrorTypeProvidesAllTypes() {
        let types = SimulatedErrorType.allCases

        #expect(types.count == 7)
        #expect(types.contains(.none))
        #expect(types.contains(.networkConnectionLost))
        #expect(types.contains(.timeout))
        #expect(types.contains(.notFound))
        #expect(types.contains(.serverError))
        #expect(types.contains(.unauthorized))
        #expect(types.contains(.badRequest))
    }

    @Test("SimulatedErrorType의 displayName은 명확하다")
    func simulatedErrorTypeDisplayNamesAreClear() {
        #expect(SimulatedErrorType.none.displayName == "정상")
        #expect(SimulatedErrorType.networkConnectionLost.displayName == "네트워크 연결 끊김")
        #expect(SimulatedErrorType.timeout.displayName == "타임아웃")
        #expect(SimulatedErrorType.notFound.displayName == "404 Not Found")
        #expect(SimulatedErrorType.serverError.displayName == "500 Server Error")
        #expect(SimulatedErrorType.unauthorized.displayName == "401 Unauthorized")
        #expect(SimulatedErrorType.badRequest.displayName == "400 Bad Request")
    }

    @Test("SimulatedErrorType의 description은 상세 정보를 제공한다")
    func simulatedErrorTypeDescriptionsProvideDetails() {
        #expect(SimulatedErrorType.none.description.contains("정상"))
        #expect(SimulatedErrorType.networkConnectionLost.description.contains("연결"))
        #expect(SimulatedErrorType.timeout.description.contains("시간"))
        #expect(SimulatedErrorType.notFound.description.contains("404"))
        #expect(SimulatedErrorType.serverError.description.contains("500"))
    }

    @Test("SimulatedErrorType의 shouldRetry는 재시도 가능 여부를 반환한다")
    func simulatedErrorTypeShouldRetryReturnsCorrectValue() {
        #expect(SimulatedErrorType.none.shouldRetry == false)
        #expect(SimulatedErrorType.networkConnectionLost.shouldRetry == true)
        #expect(SimulatedErrorType.timeout.shouldRetry == true)
        #expect(SimulatedErrorType.notFound.shouldRetry == false)
        #expect(SimulatedErrorType.serverError.shouldRetry == true)
        #expect(SimulatedErrorType.unauthorized.shouldRetry == false)
        #expect(SimulatedErrorType.badRequest.shouldRetry == false)
    }

    // MARK: - ErrorSimulationResult Tests

    @Test("ErrorSimulationResult는 성공 케이스를 생성할 수 있다")
    func errorSimulationResultCanCreateSuccessCase() {
        let result = ErrorSimulationResult.success(
            url: "https://api.example.com/posts",
            statusCode: 200,
            duration: 0.5
        )

        #expect(result.isSuccess == true)
        #expect(result.url == "https://api.example.com/posts")
        #expect(result.statusCode == 200)
        #expect(result.duration == 0.5)
    }

    @Test("ErrorSimulationResult는 실패 케이스를 생성할 수 있다")
    func errorSimulationResultCanCreateFailureCase() {
        let result = ErrorSimulationResult.failure(
            url: "https://api.example.com/posts",
            errorType: .timeout,
            attempt: 2,
            willRetry: true,
            duration: 1.5
        )

        #expect(result.isSuccess == false)
        #expect(result.url == "https://api.example.com/posts")
        #expect(result.errorType == .timeout)
        #expect(result.attempt == 2)
        #expect(result.willRetry == true)
    }

    @Test("ErrorSimulationResult의 displayMessage는 읽기 쉬운 메시지를 제공한다")
    func errorSimulationResultDisplayMessageIsReadable() {
        let success = ErrorSimulationResult.success(
            url: "https://api.example.com/posts",
            statusCode: 200,
            duration: 0.5
        )
        #expect(success.displayMessage.contains("성공"))
        #expect(success.displayMessage.contains("200"))

        let failure = ErrorSimulationResult.failure(
            url: "https://api.example.com/posts",
            errorType: .timeout,
            attempt: 1,
            willRetry: false,
            duration: 1.5
        )
        #expect(failure.displayMessage.contains("실패"))
        #expect(failure.displayMessage.contains("타임아웃"))
    }
}
