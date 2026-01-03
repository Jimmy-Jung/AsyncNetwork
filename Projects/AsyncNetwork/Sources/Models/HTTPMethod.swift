//
//  HTTPMethod.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}
