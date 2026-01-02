//
//  APITesterStateTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/02.
//

@testable import AsyncNetworkDocKit
import Foundation
import Testing

@Suite("APITesterState Tests")
@MainActor
struct APITesterStateTests {
    @available(iOS 17.0, macOS 14.0, *)

    @Test("APITesterState 초기화 시 endpointId가 올바르게 설정된다")
    @available(iOS 17.0, macOS 14.0, *)
    func initialEndpointIdIsCorrectlySet() {
        let state = APITesterState(endpointId: "endpoint-123")
        #expect(state.endpointId == "endpoint-123")
    }

    @Test("초기 상태값들이 올바르게 설정된다")
    @available(iOS 17.0, macOS 14.0, *)
    func initialStateValuesAreCorrect() {
        let state = APITesterState(endpointId: "test-endpoint")

        #expect(state.parameters.isEmpty)
        #expect(state.requestBodyFields.isEmpty)
        #expect(state.requestBody == "")
        #expect(state.isLoading == false)
        #expect(state.hasBeenRequested == false)
        #expect(state.response == "")
        #expect(state.statusCode == nil)
        #expect(state.error == nil)
        #expect(state.requestTimestamp == "")
        #expect(state.responseTimestamp == "")
        #expect(state.requestHeaders.isEmpty)
        #expect(state.responseHeaders.isEmpty)
        #expect(state.requestBodySize == 0)
        #expect(state.responseBodySize == 0)
    }

    @Test("parameters를 추가할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canAddParameters() {
        let state = APITesterState(endpointId: "test-endpoint")
        state.parameters["userId"] = "123"
        state.parameters["page"] = "1"

        #expect(state.parameters["userId"] == "123")
        #expect(state.parameters["page"] == "1")
        #expect(state.parameters.count == 2)
    }

    @Test("requestBodyFields를 추가할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canAddRequestBodyFields() {
        let state = APITesterState(endpointId: "test-endpoint")
        state.requestBodyFields["title"] = "Test Title"
        state.requestBodyFields["body"] = "Test Body"

        #expect(state.requestBodyFields["title"] == "Test Title")
        #expect(state.requestBodyFields["body"] == "Test Body")
        #expect(state.requestBodyFields.count == 2)
    }

    @Test("markAsRequested()를 호출하면 hasBeenRequested가 true가 된다")
    @available(iOS 17.0, macOS 14.0, *)
    func markAsRequestedSetsHasBeenRequestedToTrue() {
        let state = APITesterState(endpointId: "test-endpoint")
        #expect(state.hasBeenRequested == false)

        state.markAsRequested()
        #expect(state.hasBeenRequested == true)
    }

    @Test("reset()을 호출하면 모든 상태가 초기화된다")
    @available(iOS 17.0, macOS 14.0, *)
    func resetClearsAllState() {
        let state = APITesterState(endpointId: "test-endpoint")

        // 상태 값 설정
        state.parameters["userId"] = "123"
        state.requestBodyFields["title"] = "Test"
        state.requestBody = "{\"test\": true}"
        state.isLoading = true
        state.hasBeenRequested = true
        state.response = "Response data"
        state.statusCode = 200
        state.error = "Some error"
        state.requestTimestamp = "2026-01-02T10:00:00Z"
        state.responseTimestamp = "2026-01-02T10:00:01Z"
        state.requestHeaders["Authorization"] = "Bearer token"
        state.responseHeaders["Content-Type"] = "application/json"
        state.requestBodySize = 100
        state.responseBodySize = 500

        // reset 호출
        state.reset()

        // 모든 값 초기화 확인
        #expect(state.parameters.isEmpty)
        #expect(state.requestBodyFields.isEmpty)
        #expect(state.requestBody == "")
        #expect(state.isLoading == false)
        #expect(state.hasBeenRequested == false)
        #expect(state.response == "")
        #expect(state.statusCode == nil)
        #expect(state.error == nil)
        #expect(state.requestTimestamp == "")
        #expect(state.responseTimestamp == "")
        #expect(state.requestHeaders.isEmpty)
        #expect(state.responseHeaders.isEmpty)
        #expect(state.requestBodySize == 0)
        #expect(state.responseBodySize == 0)

        // endpointId는 유지됨
        #expect(state.endpointId == "test-endpoint")
    }

    @Test("로딩 상태를 변경할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canChangeLoadingState() {
        let state = APITesterState(endpointId: "test-endpoint")
        #expect(state.isLoading == false)

        state.isLoading = true
        #expect(state.isLoading == true)

        state.isLoading = false
        #expect(state.isLoading == false)
    }

    @Test("응답 데이터를 설정할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canSetResponseData() {
        let state = APITesterState(endpointId: "test-endpoint")

        state.response = "{\"id\": 1, \"name\": \"John\"}"
        state.statusCode = 200

        #expect(state.response == "{\"id\": 1, \"name\": \"John\"}")
        #expect(state.statusCode == 200)
    }

    @Test("에러 메시지를 설정할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canSetErrorMessage() {
        let state = APITesterState(endpointId: "test-endpoint")

        state.error = "Network connection failed"
        #expect(state.error == "Network connection failed")
    }
}

@Suite("APITesterStateStore Tests")
@MainActor
struct APITesterStateStoreTests {
    @available(iOS 17.0, macOS 14.0, *)

    @Test("shared 인스턴스에 접근할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canAccessSharedInstance() {
        let store = APITesterStateStore.shared
        // shared 인스턴스가 존재하는지 확인
        _ = store
    }

    @Test("새로운 endpointId로 상태를 가져오면 새 상태가 생성된다")
    @available(iOS 17.0, macOS 14.0, *)
    func getStateCreatesNewStateForNewEndpoint() {
        let store = APITesterStateStore.shared
        store.clearAllStates()

        let state = store.getState(for: "endpoint-1")
        #expect(state.endpointId == "endpoint-1")
    }

    @Test("동일한 endpointId로 여러 번 호출하면 같은 인스턴스를 반환한다")
    @available(iOS 17.0, macOS 14.0, *)
    func getStateReturnsSameInstanceForSameEndpoint() {
        let store = APITesterStateStore.shared
        store.clearAllStates()

        let state1 = store.getState(for: "endpoint-2")
        let state2 = store.getState(for: "endpoint-2")

        #expect(state1 === state2)
    }

    @Test("다른 endpointId는 서로 다른 상태 인스턴스를 가진다")
    @available(iOS 17.0, macOS 14.0, *)
    func differentEndpointsHaveDifferentStates() {
        let store = APITesterStateStore.shared
        store.clearAllStates()

        let state1 = store.getState(for: "endpoint-a")
        let state2 = store.getState(for: "endpoint-b")

        #expect(state1 !== state2)
        #expect(state1.endpointId == "endpoint-a")
        #expect(state2.endpointId == "endpoint-b")
    }

    @Test("clearState로 특정 endpoint의 상태를 제거할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func clearStateRemovesSpecificEndpointState() {
        let store = APITesterStateStore.shared
        store.clearAllStates()

        let state1 = store.getState(for: "endpoint-x")
        state1.parameters["test"] = "value"

        store.clearState(for: "endpoint-x")

        let state2 = store.getState(for: "endpoint-x")
        #expect(state1 !== state2)
        #expect(state2.parameters.isEmpty)
    }

    @Test("clearAllStates로 모든 상태를 제거할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func clearAllStatesRemovesAllEndpointStates() {
        let store = APITesterStateStore.shared
        store.clearAllStates()

        let state1 = store.getState(for: "endpoint-1")
        let state2 = store.getState(for: "endpoint-2")
        let state3 = store.getState(for: "endpoint-3")

        state1.parameters["key1"] = "value1"
        state2.parameters["key2"] = "value2"
        state3.parameters["key3"] = "value3"

        store.clearAllStates()

        let newState1 = store.getState(for: "endpoint-1")
        let newState2 = store.getState(for: "endpoint-2")
        let newState3 = store.getState(for: "endpoint-3")

        #expect(state1 !== newState1)
        #expect(state2 !== newState2)
        #expect(state3 !== newState3)
        #expect(newState1.parameters.isEmpty)
        #expect(newState2.parameters.isEmpty)
        #expect(newState3.parameters.isEmpty)
    }

    @Test("상태 변경이 같은 endpointId의 다른 참조에 반영된다")
    @available(iOS 17.0, macOS 14.0, *)
    func stateChangesAreReflectedAcrossReferences() {
        let store = APITesterStateStore.shared
        store.clearAllStates()

        let state1 = store.getState(for: "endpoint-shared")
        state1.parameters["shared"] = "data"

        let state2 = store.getState(for: "endpoint-shared")
        #expect(state2.parameters["shared"] == "data")
    }
}
