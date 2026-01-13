//
//  LoggingInterceptor.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public enum NetworkLogLevel: Int, Sendable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case fatal = 5

    public var emoji: String {
        switch self {
        case .verbose: return "💬"
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "🔥"
        }
    }
}

/// 콘솔 기반 로깅 Interceptor
///
/// RequestInterceptor를 구현하여 네트워크 요청/응답을 콘솔에 로깅합니다.
public struct ConsoleLoggingInterceptor: RequestInterceptor {
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
        dateFormatter = formatter
    }

    public func willSend(_ request: URLRequest, target _: (any APIRequest)?) async {
        guard minimumLevel.rawValue <= NetworkLogLevel.debug.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "Unknown Method"

        var log = "\n🌐 ======================= REQUEST ========================\n"
        log.append("🕐 \(timestamp) 🔍 [debug]\n")
        log.append("📍 URL: \(url)\n")
        log.append("🔧 Method: \(method)\n")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log.append("\n📋 Headers:\n")
            for (key, value) in headers {
                log.append("   \(key): \(filterSensitive(value, key: key))\n")
            }
        }

        if let body = request.httpBody, !body.isEmpty {
            log.append("\n📦 Body (\(body.count) bytes):\n")
            if let jsonString = formatJSON(data: body) {
                log.append(filterSensitiveInString(jsonString))
            } else if let bodyString = String(data: body, encoding: .utf8) {
                log.append(filterSensitiveInString(bodyString))
            }
        }

        log.append("\n=========================================================\n")
        print(log)
    }

    public func didReceive(_ response: HTTPResponse, target _: (any APIRequest)?) async {
        let level: NetworkLogLevel = response.statusCode < 400 ? .debug : .warning
        guard minimumLevel.rawValue <= level.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = response.response?.url?.absoluteString ?? "Unknown URL"
        let statusCode = response.statusCode
        let icon = statusCode < 400 ? "✅" : "⚠️"

        var log = "\n\(icon) ======================= RESPONSE =======================\n"
        log.append("🕐 \(timestamp) \(level.emoji) [\(level)]\n")
        log.append("📍 URL: \(url)\n")
        log.append("📊 Status: \(statusCode)\n")

        // Response Headers
        if let httpResponse = response.response,
           let headers = httpResponse.allHeaderFields as? [String: String],
           !headers.isEmpty
        {
            log.append("\n📋 Response Headers:\n")
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                log.append("   \(key): \(filterSensitive(value, key: key))\n")
            }
        }

        if !response.data.isEmpty {
            log.append("\n📦 Response Body (\(response.data.count) bytes):\n")
            if let jsonString = formatJSON(data: response.data) {
                log.append(jsonString)
            } else if let bodyString = String(data: response.data, encoding: .utf8) {
                log.append(bodyString)
            }
        }

        log.append("\n=========================================================\n")
        print(log)
    }

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
