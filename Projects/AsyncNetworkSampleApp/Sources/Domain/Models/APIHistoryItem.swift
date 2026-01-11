//
//  APIHistoryItem.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation
import UIKit

// MARK: - APIHistoryItem

/// Postman 스타일 History Item
struct APIHistoryItem: Equatable, Sendable, Identifiable {
    let id: UUID
    let method: String
    let path: String
    let statusCode: Int
    let statusText: String
    let duration: Int // milliseconds
    let size: String // "1.2KB"
    let requestHeaders: [String: String]
    let requestBody: String?
    let requestParams: [String: String]
    let responseBody: String
    let responseHeaders: [String: String]
    let timestamp: Date

    init(
        method: String,
        path: String,
        statusCode: Int,
        statusText: String,
        duration: Int,
        size: String,
        requestHeaders: [String: String] = [:],
        requestBody: String? = nil,
        requestParams: [String: String] = [:],
        responseBody: String,
        responseHeaders: [String: String],
        timestamp: Date
    ) {
        id = UUID()
        self.method = method
        self.path = path
        self.statusCode = statusCode
        self.statusText = statusText
        self.duration = duration
        self.size = size
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.requestParams = requestParams
        self.responseBody = responseBody
        self.responseHeaders = responseHeaders
        self.timestamp = timestamp
    }

    var statusColor: UIColor {
        switch statusCode {
        case 200 ..< 300: return .systemGreen
        case 300 ..< 400: return .systemYellow
        case 400 ..< 500: return .systemOrange
        case 500...: return .systemRed
        default: return .label
        }
    }

    var methodColor: UIColor {
        switch method.uppercased() {
        case "GET": return .systemGreen
        case "POST": return .systemOrange
        case "PUT": return .systemBlue
        case "PATCH": return .systemIndigo
        case "DELETE": return .systemRed
        default: return .systemGray
        }
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - ResponseStatus

/// Response 상태 정보
struct ResponseStatus: Equatable, Sendable {
    let code: Int
    let text: String
    let duration: Int // milliseconds
    let size: String // "1.2KB"

    var displayText: String {
        "Status: \(code) \(text) | Time: \(duration)ms | Size: \(size)"
    }

    var color: UIColor {
        switch code {
        case 200 ..< 300: return .systemGreen
        case 300 ..< 400: return .systemYellow
        case 400 ..< 500: return .systemOrange
        case 500...: return .systemRed
        default: return .label
        }
    }
}
