//
//  NetworkLogger.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - LogLevel

/// 로그 레벨
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

// MARK: - NetworkLogger

/// 네트워크 로깅을 위한 프로토콜
///
/// **설계 원칙:**
/// - 외부 로깅 SDK 주입 가능 (TraceKit, Firebase, Sentry 등)
/// - 기본 구현체는 Console 출력
/// - 민감 정보 필터링 가능
///
/// **사용 예시:**
/// ```swift
/// // 1. 기본 Console 로거
/// let logger = ConsoleNetworkLogger()
///
/// // 2. TraceKit 로거 (Example 앱에서)
/// let logger = TraceKitNetworkLogger()
///
/// // 3. 로거 주입
/// let client = HTTPClient(logger: logger)
/// ```
public protocol NetworkLogger: Sendable {
    /// HTTP 요청 시작 로깅
    func logRequest(
        _ request: URLRequest,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    )

    /// HTTP 응답 수신 로깅
    func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    )

    /// 네트워크 에러 로깅
    func logError(
        _ error: Error,
        request: URLRequest?,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    )

    /// 일반 메시지 로깅
    func log(
        _ message: String,
        level: NetworkLogLevel,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - Default Implementation

public extension NetworkLogger {
    func logRequest(
        _ request: URLRequest,
        level: NetworkLogLevel = .debug,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        logRequest(request, level: level, file: file, function: function, line: line)
    }

    func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval,
        level: NetworkLogLevel = .debug,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        logResponse(response, data: data, duration: duration, level: level, file: file, function: function, line: line)
    }

    func logError(
        _ error: Error,
        request: URLRequest? = nil,
        level: NetworkLogLevel = .error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        logError(error, request: request, level: level, file: file, function: function, line: line)
    }

    func log(
        _ message: String,
        level: NetworkLogLevel = .info,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: level, file: file, function: function, line: line)
    }
}

// MARK: - ConsoleNetworkLogger

/// 기본 콘솔 로거 (print 기반)
public struct ConsoleNetworkLogger: NetworkLogger {
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
        function _: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "Unknown Method"

        var log = "\n🌐 ======================= REQUEST ========================\n"
        log.append("🕐 \(timestamp) \(level.emoji) [\(level)]\n")
        log.append("📍 URL: \(url)\n")
        log.append("🔧 Method: \(method)\n")
        log.append("📂 File: \(file):\(line)\n")

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

    public func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval,
        level: NetworkLogLevel,
        file: String,
        function _: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = response.url?.absoluteString ?? "Unknown URL"
        let statusCode = response.statusCode
        let icon = statusCode < 400 ? "✅" : "⚠️"

        var log = "\n\(icon) ======================= RESPONSE =======================\n"
        log.append("🕐 \(timestamp) \(level.emoji) [\(level)]\n")
        log.append("📍 URL: \(url)\n")
        log.append("📊 Status: \(statusCode)\n")
        log.append("⏱️ Duration: \(String(format: "%.3f", duration))s\n")
        log.append("📂 File: \(file):\(line)\n")

        if !data.isEmpty {
            log.append("\n📦 Response Body (\(data.count) bytes):\n")
            if let jsonString = formatJSON(data: data) {
                log.append(jsonString)
            } else if let bodyString = String(data: data, encoding: .utf8) {
                log.append(bodyString)
            }
        }

        log.append("\n=========================================================\n")
        print(log)
    }

    public func logError(
        _ error: Error,
        request: URLRequest?,
        level: NetworkLogLevel,
        file: String,
        function _: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let url = request?.url?.absoluteString ?? "Unknown URL"

        var log = "\n❌ ========================= ERROR =========================\n"
        log.append("🕐 \(timestamp) \(level.emoji) [\(level)]\n")
        log.append("📍 URL: \(url)\n")
        log.append("🚨 Error: \(error.localizedDescription)\n")
        log.append("📂 File: \(file):\(line)\n")
        log.append("=========================================================\n")

        print(log)
    }

    public func log(
        _ message: String,
        level: NetworkLogLevel,
        file: String,
        function _: String,
        line: Int
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] \(level.emoji) [\(level)] \(message) - \(file):\(line)")
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
                "\(key)=([^&\\s]*)"
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

// MARK: - SilentNetworkLogger

/// 로깅을 하지 않는 로거 (프로덕션 환경용)
public struct SilentNetworkLogger: NetworkLogger {
    public init() {}

    public func logRequest(
        _: URLRequest,
        level _: NetworkLogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}
    
    public func logResponse(
        _: HTTPURLResponse,
        data _: Data,
        duration _: TimeInterval,
        level _: NetworkLogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}
    
    public func logError(
        _: Error,
        request _: URLRequest?,
        level _: NetworkLogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}
    
    public func log(
        _: String,
        level _: NetworkLogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}
}
