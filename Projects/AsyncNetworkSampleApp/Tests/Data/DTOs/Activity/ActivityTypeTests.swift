//
//  ActivityTypeTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("ActivityType Tests")
struct ActivityTypeTests {
    @Test("ActivityType의 모든 케이스가 올바른 rawValue를 가지는지 확인")
    func activityTypeRawValues() {
        #expect(ActivityType.login.rawValue == "login")
        #expect(ActivityType.purchase.rawValue == "purchase")
        #expect(ActivityType.view.rawValue == "view")
    }

    @Test("ActivityType이 rawValue로부터 초기화되는지 확인")
    func activityTypeInit() {
        #expect(ActivityType(rawValue: "login") == .login)
        #expect(ActivityType(rawValue: "purchase") == .purchase)
        #expect(ActivityType(rawValue: "view") == .view)
        #expect(ActivityType(rawValue: "unknown") == nil)
    }

    @Test("ActivityType이 CaseIterable을 준수하는지 확인")
    func activityTypeCaseIterable() {
        let allCases = ActivityType.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.login))
        #expect(allCases.contains(.purchase))
        #expect(allCases.contains(.view))
    }
}
