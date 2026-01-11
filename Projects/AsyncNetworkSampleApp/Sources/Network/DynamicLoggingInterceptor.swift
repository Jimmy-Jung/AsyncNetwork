//
//  DynamicLoggingInterceptor.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import Foundation

/// 동적으로 로그 레벨을 변경할 수 있는 로깅 인터셉터
///
/// ConsoleLoggingInterceptor를 감싸서 런타임에 로그 레벨을 변경할 수 있게 합니다.
public actor DynamicLoggingInterceptor: RequestInterceptor {
    private var currentLevel: NetworkLogLevel
    private let sensitiveKeys: [String]

    public init(
        initialLevel: NetworkLogLevel = .verbose,
        sensitiveKeys: [String] = ["password", "token", "key", "secret", "enc_key", "mem_key"]
    ) {
        currentLevel = initialLevel
        self.sensitiveKeys = sensitiveKeys
    }

    /// 로그 레벨을 변경합니다
    public func setLevel(_ level: NetworkLogLevel) {
        currentLevel = level
    }

    /// 현재 로그 레벨을 반환합니다
    public func getCurrentLevel() -> NetworkLogLevel {
        currentLevel
    }

    public func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
        let interceptor = ConsoleLoggingInterceptor(
            minimumLevel: currentLevel,
            sensitiveKeys: sensitiveKeys
        )
        await interceptor.willSend(request, target: target)
    }

    public func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
        let interceptor = ConsoleLoggingInterceptor(
            minimumLevel: currentLevel,
            sensitiveKeys: sensitiveKeys
        )
        await interceptor.didReceive(response, target: target)
    }
}
