//
//  RequestParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// Property Wrapper가 URLRequest에 적용되는 공통 프로토콜
public protocol RequestParameter: Sendable {
    func apply(to request: inout URLRequest, key: String) throws
}
