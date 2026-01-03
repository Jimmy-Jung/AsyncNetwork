//
//  RequestInterceptor.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// 네트워크 요청/응답을 가로채서 전처리 또는 후처리를 수행하는 프로토콜
///
/// RequestInterceptor는 세 가지 라이프사이클 훅을 제공합니다:
/// 1. `prepare(_:target:)` - 요청 전송 전 URLRequest 수정 (인증 토큰 주입 등)
/// 2. `willSend(_:target:)` - 요청 직전 옵저버 훅 (로깅, Analytics 등)
/// 3. `didReceive(_:target:)` - 응답 수신 후 옵저버 훅 (로깅, 메트릭 수집 등)
public protocol RequestInterceptor: Sendable {
    func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws
    func willSend(_ request: URLRequest, target: (any APIRequest)?) async
    func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async
}

public extension RequestInterceptor {
    func prepare(_: inout URLRequest, target _: (any APIRequest)?) async throws {}
    func willSend(_: URLRequest, target _: (any APIRequest)?) async {}
    func didReceive(_: HTTPResponse, target _: (any APIRequest)?) async {}
}
