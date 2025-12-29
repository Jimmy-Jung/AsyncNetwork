//
//  TraceKitNetworkLogger.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation
import NetworkKit
import TraceKit

// MARK: - TraceKitNetworkLogger

/// TraceKit 기반 네트워크 로거
///
/// NetworkKit의 NetworkLogger 프로토콜을 구현하여
/// 모든 네트워크 요청/응답을 TraceKit으로 로깅합니다.
public struct TraceKitNetworkLogger: NetworkLogger {
    private let minimumLevel: NetworkLogLevel
    private let dateFormatter: DateFormatter
    private let sensitiveKeys: Set<String>

    public init(
        minimumLevel: NetworkLogLevel = .verbose,
        sensitiveKeys: [String] = ["password", "token", "key", "secret", "enc_key", "mem_key"]
    ) {
        self.minimumLevel = minimumLevel
        self.sensitiveKeys = Set(sensitiveKeys)

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    public func logRequest(
        _ request: URLRequest,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "Unknown Method"

        var logParts: [String] = [
            "\n🌐 ======================= REQUEST ========================",
            "🕐 \(timestamp) \(level.emoji) [\(level)]",
            "📍 URL: \(url)",
            "🔧 Method: \(method)",
            "📂 File: \(file):\(line)",
        ]

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logParts.append("\n📋 Headers:")
            for (key, value) in headers {
                logParts.append("   \(key): \(filterSensitive(value, key: key))")
            }
        }

        if let body = request.httpBody, !body.isEmpty {
            logParts.append("\n📦 Body (\(body.count) bytes):")
            if let jsonString = formatJSON(data: body) {
                logParts.append(filterSensitiveInString(jsonString))
            } else if let bodyString = String(data: body, encoding: .utf8) {
                logParts.append(filterSensitiveInString(bodyString))
            }
        }

        logParts.append("\n=========================================================")

        let log = logParts.joined(separator: "\n")

        TraceKit.log(
            level: level.traceLevel,
            log,
            category: "Network",
            file: file,
            function: function,
            line: line
        )
    }

    public func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = response.url?.absoluteString ?? "Unknown URL"
        let statusCode = response.statusCode
        let icon = statusCode < 400 ? "✅" : "⚠️"

        var logParts: [String] = [
            "\n\(icon) ======================= RESPONSE =======================",
            "🕐 \(timestamp) \(level.emoji) [\(level)]",
            "📍 URL: \(url)",
            "📊 Status: \(statusCode)",
            "⏱️ Duration: \(String(format: "%.3f", duration))s",
            "📂 File: \(file):\(line)",
        ]

        if !data.isEmpty {
            logParts.append("\n📦 Response Body (\(data.count) bytes):")
            if let jsonString = formatJSON(data: data) {
                logParts.append(jsonString)
            } else if let bodyString = String(data: data, encoding: .utf8) {
                logParts.append(bodyString)
            }
        }

        logParts.append("\n=========================================================")

        let log = logParts.joined(separator: "\n")

        TraceKit.log(
            level: level.traceLevel,
            log,
            category: "Network",
            file: file,
            function: function,
            line: line
        )
    }

    public func logError(
        _ error: Error,
        request: URLRequest?,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = request?.url?.absoluteString ?? "Unknown URL"

        let logParts: [String] = [
            "\n❌ ========================= ERROR =========================",
            "🕐 \(timestamp) \(level.emoji) [\(level)]",
            "📍 URL: \(url)",
            "🚨 Error: \(error.localizedDescription)",
            "📂 File: \(file):\(line)",
            "=========================================================",
        ]

        let log = logParts.joined(separator: "\n")

        TraceKit.log(
            level: .error,
            log,
            category: "Network",
            file: file,
            function: function,
            line: line
        )
    }

    public func log(
        _ message: String,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let log = "[\(timestamp)] \(level.emoji) [\(level)] \(message) - \(file):\(line)"

        TraceKit.log(
            level: level.traceLevel,
            log,
            category: "Network",
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Private Helpers

    private func filterSensitive(_ value: String, key: String) -> String {
        let lowercasedKey = key.lowercased()
        for sensitiveKey in sensitiveKeys where lowercasedKey.contains(sensitiveKey) {
            return "*****"
        }
        return value
    }

    private func filterSensitiveInString(_ string: String) -> String {
        var filtered = string

        for key in sensitiveKeys {
            let patterns = [
                "\"\(key)\"\\s*:\\s*\"[^\"]*\"",
                "\(key)=([^&\\s]*)",
            ]

            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    filtered = regex.stringByReplacingMatches(
                        in: filtered,
                        options: [],
                        range: NSRange(location: 0, length: filtered.count),
                        withTemplate: "\"\(key)\":\"*****\""
                    )
                }
            }
        }

        return filtered
    }

    private func formatJSON(data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: jsonObject,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let jsonString = String(data: prettyData, encoding: .utf8)
        else {
            return nil
        }
        return jsonString
    }
}

// MARK: - NetworkLogLevel Extension

extension NetworkLogLevel {
    var traceLevel: TraceLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
}
