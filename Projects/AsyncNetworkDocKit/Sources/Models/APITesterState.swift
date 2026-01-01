//
//  APITesterState.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// API 테스터 상태 모델
struct APITesterState: Sendable {
    var parameters: [String: String] = [:]
    var requestBody: String = ""
    var isLoading: Bool = false
    var response: String = ""
    var statusCode: Int?
    var error: String?
}

