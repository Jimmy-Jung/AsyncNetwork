//
//  RequestBody.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// Request body를 자동으로 JSON 인코딩
@propertyWrapper
public struct RequestBody<Value: Encodable & Sendable>: RequestParameter {
    public var wrappedValue: Value?

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }

    public func apply(to request: inout URLRequest, key _: String) throws {
        guard let value = wrappedValue else { return }

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(value)

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}
