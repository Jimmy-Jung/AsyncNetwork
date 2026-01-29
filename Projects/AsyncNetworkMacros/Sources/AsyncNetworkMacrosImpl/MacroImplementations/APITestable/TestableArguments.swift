//
//  TestableArguments.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//

/// @APITestable 매크로 인자를 담는 구조체
struct TestableArguments {
    let scenarios: [String]
    let errorExamples: [String: String]
}
