//
//  APIPlaygroundStateTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/11.
//

@testable import AsyncNetworkSampleApp
import Testing

@Suite("APIPlaygroundState Tests")
@MainActor
struct APIPlaygroundStateTests {
    @Test("State 초기 생성")
    func stateInitialization() {
        // Given & When
        let state = APIPlaygroundState(methodId: "getAllPosts")

        // Then
        #expect(state.methodId == "getAllPosts")
        #expect(state.parameters.isEmpty)
        #expect(state.headerFields.isEmpty)
        #expect(state.requestBodyFields.isEmpty)
        #expect(state.requestBody == "")
        #expect(state.isLoading == false)
        #expect(state.hasBeenRequested == false)
        #expect(state.response == "")
        #expect(state.statusCode == nil)
        #expect(state.error == nil)
    }

    @Test("State 초기화")
    func stateReset() {
        // Given
        let state = APIPlaygroundState(methodId: "createPost")
        state.parameters["id"] = "123"
        state.requestBody = "test body"
        state.isLoading = true
        state.hasBeenRequested = true
        state.response = "test response"
        state.statusCode = 200

        // When
        state.reset()

        // Then
        #expect(state.parameters.isEmpty)
        #expect(state.requestBody == "")
        #expect(state.isLoading == false)
        #expect(state.hasBeenRequested == false)
        #expect(state.response == "")
        #expect(state.statusCode == nil)
    }

    @Test("요청 마킹")
    func testMarkAsRequested() {
        // Given
        let state = APIPlaygroundState(methodId: "deletePost")
        #expect(state.hasBeenRequested == false)

        // When
        state.markAsRequested()

        // Then
        #expect(state.hasBeenRequested == true)
    }

    @Test("StateStore - 상태 가져오기")
    func stateStoreGet() {
        // Given
        let store = APIPlaygroundStateStore.shared

        // When
        let state1 = store.getState(for: "test1")
        let state2 = store.getState(for: "test1") // 같은 ID로 다시 요청
        let state3 = store.getState(for: "test2") // 다른 ID

        // Then
        #expect(state1.methodId == "test1")
        #expect(state2.methodId == "test1")
        #expect(state3.methodId == "test2")
        #expect(state1 === state2) // 같은 인스턴스
        #expect(state1 !== state3) // 다른 인스턴스

        // Cleanup
        store.clearAllStates()
    }

    @Test("StateStore - 상태 삭제")
    func stateStoreClear() {
        // Given
        let store = APIPlaygroundStateStore.shared
        let state1 = store.getState(for: "test1")

        // When
        store.clearState(for: "test1")
        let state2 = store.getState(for: "test1")

        // Then
        #expect(state1 !== state2) // 삭제 후 다시 생성되므로 다른 인스턴스

        // Cleanup
        store.clearAllStates()
    }

    @Test("StateStore - 모든 상태 삭제")
    func stateStoreClearAll() {
        // Given
        let store = APIPlaygroundStateStore.shared
        let state1 = store.getState(for: "test1")
        let state2 = store.getState(for: "test2")

        // When
        store.clearAllStates()
        let newState1 = store.getState(for: "test1")
        let newState2 = store.getState(for: "test2")

        // Then
        #expect(state1 !== newState1)
        #expect(state2 !== newState2)
    }
}
