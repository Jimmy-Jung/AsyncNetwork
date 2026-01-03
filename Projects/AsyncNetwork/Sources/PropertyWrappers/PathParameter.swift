//
//  PathParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// Path parameter를 자동으로 치환
@propertyWrapper
public struct PathParameter<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value
    private let customKey: String?

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        customKey = nil
    }

    public init(wrappedValue: Value, key: String) {
        self.wrappedValue = wrappedValue
        customKey = key
    }

    public func apply(to request: inout URLRequest, key: String) throws {
        guard let url = request.url else { return }

        let parameterKey = customKey ?? key
        let placeholder = "{\(parameterKey)}"
        let replaced = url.absoluteString.replacingOccurrences(
            of: placeholder,
            with: "\(wrappedValue)"
        )

        if let newURL = URL(string: replaced) {
            request.url = newURL
        }
    }
}
