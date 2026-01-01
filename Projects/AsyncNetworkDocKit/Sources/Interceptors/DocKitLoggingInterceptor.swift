//
//  DocKitLoggingInterceptor.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import Foundation
import AsyncNetworkCore

/// DocKit용 Interceptor (UI에 request/response 정보 전달)
@MainActor
public class DocKitLoggingInterceptor: RequestInterceptor {
    private let dateFormatter: DateFormatter
    
    // 콜백으로 정보 전달
    public var onRequestSent: ((URLRequest, String) -> Void)?
    public var onResponseReceived: ((HTTPResponse, String) -> Void)?
    
    public init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        dateFormatter = formatter
    }
    
    public func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
        let timestamp = dateFormatter.string(from: Date())
        await onRequestSent?(request, timestamp)
    }
    
    public func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
        let timestamp = dateFormatter.string(from: Date())
        await onResponseReceived?(response, timestamp)
    }
}

