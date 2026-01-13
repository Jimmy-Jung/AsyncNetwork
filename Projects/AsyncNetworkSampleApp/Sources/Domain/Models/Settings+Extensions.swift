//
//  Settings+Extensions.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import Foundation

// MARK: - LoggingLevel → NetworkLogLevel

extension LoggingLevel {
    /// AsyncNetwork의 NetworkLogLevel로 변환합니다
    var networkLogLevel: NetworkLogLevel {
        switch self {
        case .verbose:
            return .verbose
        case .info:
            return .info
        case .error:
            return .error
        case .none:
            return .fatal // fatal로 설정하면 모든 로그가 비활성화됨
        }
    }
}

// MARK: - NetworkLogLevel → LoggingLevel

extension NetworkLogLevel {
    /// LoggingLevel로 변환합니다
    var loggingLevel: LoggingLevel {
        switch self {
        case .verbose, .debug:
            return .verbose
        case .info, .warning:
            return .info
        case .error:
            return .error
        case .fatal:
            return .none
        }
    }
}
