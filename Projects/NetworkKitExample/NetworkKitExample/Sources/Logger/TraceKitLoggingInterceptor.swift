//
//  TraceKitLoggingInterceptor.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation
import NetworkKit
import TraceKit

// MARK: - TraceKitLoggingInterceptor

/// TraceKit 기반 로깅 Interceptor
///
/// RequestInterceptor를 구현하여 모든 네트워크 요청/응답을
/// TraceKit으로 로깅합니다.
///
/// ## 사용 예시
///
/// ```swift
/// let loggingInterceptor = TraceKitLoggingInterceptor(
///     minimumLevel: .verbose,
///     sensitiveKeys: ["password", "token"]
/// )
///
/// let service = NetworkService(
///     httpClient: HTTPClient(),
///     retryPolicy: .default,
///     configuration: .development,
///     responseProcessor: ResponseProcessor(),
///     interceptors: [loggingInterceptor]
/// )
/// ```
public struct TraceKitLoggingInterceptor: RequestInterceptor {
    private let minimumLevel: NetworkLogLevel
    private let dateFormatter: DateFormatter
    private let sensitiveKeys: Set<String>

    public init(
        minimumLevel: NetworkLogLevel = .verbose,
        sensitiveKeys: [String] = ["password", "token", "key", "secret", "enc_key", "mem_key"]
    ) {
        self.minimumLevel = minimumLevel
        self.sensitiveKeys = Set(sensitiveKeys)

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        self.dateFormatter = formatter
    }

    // MARK: - RequestInterceptor

    public func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
        guard minimumLevel.rawValue <= NetworkLogLevel.debug.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "Unknown Method"

        var logParts: [String] = [
            "\n🌐 ======================= REQUEST ========================",
            "🕐 \(timestamp) 🔍 [debug]",
            "📍 URL: \(url)",
            "🔧 Method: \(method)",
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
            level: .debug,
            log,
            category: "Network"
        )
    }

    public func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
        let level: NetworkLogLevel = response.statusCode < 400 ? .debug : .warning
        guard minimumLevel.rawValue <= level.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = response.response?.url?.absoluteString ?? "Unknown URL"
        let statusCode = response.statusCode
        let icon = statusCode < 400 ? "✅" : "⚠️"

        var logParts: [String] = [
            "\n\(icon) ======================= RESPONSE =======================",
            "🕐 \(timestamp) \(level.emoji) [\(level)]",
            "📍 URL: \(url)",
            "📊 Status: \(statusCode)",
        ]

        if !response.data.isEmpty {
            logParts.append("\n📦 Response Body (\(response.data.count) bytes):")
            if let jsonString = formatJSON(data: response.data) {
                logParts.append(jsonString)
            } else if let bodyString = String(data: response.data, encoding: .utf8) {
                logParts.append(bodyString)
            }
        }

        logParts.append("\n=========================================================")

        let log = logParts.joined(separator: "\n")

        TraceKit.log(
            level: level.traceLevel,
            log,
            category: "Network"
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

