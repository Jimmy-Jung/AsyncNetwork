//
//  APITesterState.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import Foundation
import Observation

/// API 테스터 상태 모델
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class APITesterState {
    // 입력 상태
    var parameters: [String: String] = [:]
    var headerFields: [String: String] = [:] // 헤더 입력값
    var requestBodyFields: [String: String] = [:]
    var requestBody: String = ""

    // 요청/응답 상태
    var isLoading: Bool = false
    var hasBeenRequested: Bool = false
    var response: String = ""
    var statusCode: Int?
    var error: String?

    // 로깅 정보
    var requestTimestamp: String = ""
    var responseTimestamp: String = ""
    var requestHeaders: [String: String] = [:]
    var responseHeaders: [String: String] = [:]
    var requestBodySize: Int = 0
    var responseBodySize: Int = 0

    // 메타데이터
    let endpointId: String

    init(endpointId: String) {
        self.endpointId = endpointId
    }

    /// 상태 초기화
    func reset() {
        parameters.removeAll()
        headerFields.removeAll()
        requestBodyFields.removeAll()
        requestBody = ""
        isLoading = false
        hasBeenRequested = false
        response = ""
        statusCode = nil
        error = nil
        requestTimestamp = ""
        responseTimestamp = ""
        requestHeaders.removeAll()
        responseHeaders.removeAll()
        requestBodySize = 0
        responseBodySize = 0
    }

    /// 요청 시작 마킹
    func markAsRequested() {
        hasBeenRequested = true
    }
}

/// API 테스터 상태 저장소
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class APITesterStateStore {
    static let shared = APITesterStateStore()

    private var states: [String: APITesterState] = [:]

    private init() {}

    /// 특정 endpoint의 상태 가져오기 (없으면 새로 생성)
    func getState(for endpointId: String) -> APITesterState {
        if let existing = states[endpointId] {
            return existing
        }
        let newState = APITesterState(endpointId: endpointId)
        states[endpointId] = newState
        return newState
    }

    /// 특정 endpoint의 상태 초기화
    func clearState(for endpointId: String) {
        states.removeValue(forKey: endpointId)
    }

    /// 모든 상태 초기화
    func clearAllStates() {
        states.removeAll()
    }
}
