//
//  APITesterState.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import Foundation
import Observation

@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class APITesterState {
    var parameters: [String: String] = [:]
    var headerFields: [String: String] = [:]
    var requestBodyFields: [String: String] = [:]
    var requestBody: String = ""
    var arrayItems: [String: [Int: [String: String]]] = [:]
    var arrayItemCounts: [String: Int] = [:]
    var isLoading: Bool = false
    var hasBeenRequested: Bool = false
    var response: String = ""
    var statusCode: Int?
    var error: String?
    var requestTimestamp: String = ""
    var responseTimestamp: String = ""
    var requestHeaders: [String: String] = [:]
    var responseHeaders: [String: String] = [:]
    var requestBodySize: Int = 0
    var responseBodySize: Int = 0
    let endpointId: String

    init(endpointId: String) {
        self.endpointId = endpointId
    }

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

    func markAsRequested() {
        hasBeenRequested = true
    }
}

@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class APITesterStateStore {
    static let shared = APITesterStateStore()

    private var states: [String: APITesterState] = [:]

    private init() {}

    func getState(for endpointId: String) -> APITesterState {
        if let existing = states[endpointId] {
            return existing
        }
        let newState = APITesterState(endpointId: endpointId)
        states[endpointId] = newState
        return newState
    }

    func clearState(for endpointId: String) {
        states.removeValue(forKey: endpointId)
    }

    func clearAllStates() {
        states.removeAll()
    }
}
