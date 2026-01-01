//
//  RequestParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// Property Wrapper가 URLRequest에 적용되는 공통 프로토콜
public protocol RequestParameter: Sendable {
    /// URLRequest에 파라미터를 적용
    /// - Parameters:
    ///   - request: 수정할 URLRequest
    ///   - key: 프로퍼티 이름
    func apply(to request: inout URLRequest, key: String) throws
}

