//
//  APIPlaygroundState.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation
import Observation

/// API Playground의 상태를 관리하는 Observable 클래스
@MainActor
@Observable
final class APIPlaygroundState {
    // MARK: - Properties

    /// 현재 입력된 파라미터 값들
    var parameters: [String: String] = [:]

    /// 현재 입력된 헤더 값들
    var headerFields: [String: String] = [:]

    /// Request Body 필드 값들
    var requestBodyFields: [String: String] = [:]

    /// Request Body (Raw JSON)
    var requestBody: String = ""

    /// 배열 타입 필드의 아이템들 ([arrayPath: [index: [fieldName: value]]])
    var arrayItems: [String: [Int: [String: String]]] = [:]

    /// 배열 타입 필드의 아이템 개수 ([arrayPath: count])
    var arrayItemCounts: [String: Int] = [:]

    /// 로딩 상태
    var isLoading: Bool = false

    /// 요청이 한 번이라도 실행되었는지 여부
    var hasBeenRequested: Bool = false

    /// 응답 본문
    var response: String = ""

    /// HTTP 상태 코드
    var statusCode: Int?

    /// 에러 메시지
    var error: String?

    /// 요청 타임스탬프
    var requestTimestamp: String = ""

    /// 응답 타임스탬프
    var responseTimestamp: String = ""

    /// 요청 헤더 (실제 전송된 헤더)
    var requestHeaders: [String: String] = [:]

    /// 응답 헤더
    var responseHeaders: [String: String] = [:]

    /// 요청 Body 크기 (bytes)
    var requestBodySize: Int = 0

    /// 응답 Body 크기 (bytes)
    var responseBodySize: Int = 0

    /// 관련된 API 메서드 ID
    let methodId: String

    // MARK: - Initialization

    init(methodId: String) {
        self.methodId = methodId
    }

    // MARK: - Methods

    /// 상태 초기화
    func reset() {
        parameters.removeAll()
        headerFields.removeAll()
        requestBodyFields.removeAll()
        requestBody = ""
        arrayItems.removeAll()
        arrayItemCounts.removeAll()
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

    /// 요청이 실행되었음을 표시
    func markAsRequested() {
        hasBeenRequested = true
    }
}

/// API Playground State 저장소 (각 API 메서드별 상태 유지)
@MainActor
final class APIPlaygroundStateStore {
    static let shared = APIPlaygroundStateStore()

    private var states: [String: APIPlaygroundState] = [:]

    private init() {}

    /// 특정 메서드의 상태 가져오기 (없으면 새로 생성)
    func getState(for methodId: String) -> APIPlaygroundState {
        if let existing = states[methodId] {
            return existing
        }
        let newState = APIPlaygroundState(methodId: methodId)
        states[methodId] = newState
        return newState
    }

    /// 특정 메서드의 상태 삭제
    func clearState(for methodId: String) {
        states.removeValue(forKey: methodId)
    }

    /// 모든 상태 삭제
    func clearAllStates() {
        states.removeAll()
    }
}
