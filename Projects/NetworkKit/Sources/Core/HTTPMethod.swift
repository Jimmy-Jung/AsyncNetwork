//
//  HTTPMethod.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// HTTP 메서드
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}
