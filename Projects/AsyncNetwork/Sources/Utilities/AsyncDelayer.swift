//
//  AsyncDelayer.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public protocol AsyncDelayer: Sendable {
    func sleep(seconds: TimeInterval) async throws
}

public struct SystemDelayer: AsyncDelayer {
    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

public struct TestDelayer: AsyncDelayer {
    public init() {}

    public func sleep(seconds _: TimeInterval) async throws {}
}

public actor ControlledDelayer: AsyncDelayer {
    private var sleepCalls: [(seconds: TimeInterval, timestamp: Date)] = []

    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        sleepCalls.append((seconds: seconds, timestamp: Date()))
    }

    public func getSleepCalls() -> [(seconds: TimeInterval, timestamp: Date)] {
        return sleepCalls
    }

    public func reset() {
        sleepCalls.removeAll()
    }
}
