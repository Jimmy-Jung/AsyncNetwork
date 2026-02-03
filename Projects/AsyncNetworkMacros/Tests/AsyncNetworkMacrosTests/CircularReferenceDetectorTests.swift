//
//  CircularReferenceDetectorTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/02/03.
//

import Testing
import Foundation
@testable import AsyncNetworkMacrosImpl

@Suite("CircularReferenceDetector 테스트")
struct CircularReferenceDetectorTests {
    
    @Test("정상적인 타입 방문")
    func testNormalVisit() throws {
        var detector = CircularReferenceDetector()
        
        // 첫 번째 타입 방문
        #expect(detector.canVisit(typeName: "User"))
        try detector.enter(typeName: "User")
        #expect(detector.depth == 1)
        #expect(detector.currentPath.contains("User"))
        
        // 두 번째 타입 방문
        #expect(detector.canVisit(typeName: "Post"))
        try detector.enter(typeName: "Post")
        #expect(detector.depth == 2)
        #expect(detector.currentPath.contains("Post"))
        
        // 방문 종료
        detector.exit(typeName: "Post")
        #expect(detector.depth == 1)
        #expect(!detector.currentPath.contains("Post"))
        
        detector.exit(typeName: "User")
        #expect(detector.depth == 0)
        #expect(detector.currentPath.isEmpty)
    }
    
    @Test("순환 참조 감지")
    func testCircularReferenceDetection() throws {
        var detector = CircularReferenceDetector()
        
        try detector.enter(typeName: "User")
        try detector.enter(typeName: "Post")
        try detector.enter(typeName: "Comment")
        
        // User를 다시 방문하려고 하면 순환 참조 에러
        #expect(!detector.canVisit(typeName: "User"))
        
        #expect(throws: CircularReferenceError.self) {
            try detector.enter(typeName: "User")
        }
    }
    
    @Test("최대 깊이 초과 감지")
    func testMaxDepthExceeded() throws {
        var detector = CircularReferenceDetector()
        
        // 최대 깊이까지 방문
        try detector.enter(typeName: "Type1")
        try detector.enter(typeName: "Type2")
        try detector.enter(typeName: "Type3")
        try detector.enter(typeName: "Type4")
        try detector.enter(typeName: "Type5")
        
        #expect(detector.depth == 5)
        
        // 최대 깊이 초과 시도
        #expect(!detector.canVisit(typeName: "Type6"))
        
        #expect(throws: CircularReferenceError.self) {
            try detector.enter(typeName: "Type6")
        }
    }
    
    @Test("중첩된 방문 및 종료")
    func testNestedVisits() throws {
        var detector = CircularReferenceDetector()
        
        try detector.enter(typeName: "A")
        #expect(detector.depth == 1)
        
        try detector.enter(typeName: "B")
        #expect(detector.depth == 2)
        
        try detector.enter(typeName: "C")
        #expect(detector.depth == 3)
        
        detector.exit(typeName: "C")
        #expect(detector.depth == 2)
        
        // C는 이제 다시 방문 가능
        #expect(detector.canVisit(typeName: "C"))
        try detector.enter(typeName: "C")
        #expect(detector.depth == 3)
        
        detector.exit(typeName: "C")
        detector.exit(typeName: "B")
        detector.exit(typeName: "A")
        #expect(detector.depth == 0)
    }
    
    @Test("순환 참조 에러 메시지 검증")
    func testCircularReferenceErrorMessage() throws {
        var detector = CircularReferenceDetector()
        
        try detector.enter(typeName: "User")
        try detector.enter(typeName: "Post")
        
        do {
            try detector.enter(typeName: "User")
            Issue.record("순환 참조 에러가 발생해야 합니다")
        } catch let error as CircularReferenceError {
            let message = error.description
            #expect(message.contains("순환 참조가 감지되었습니다"))
            #expect(message.contains("User"))
            #expect(message.contains("해결 방법"))
        }
    }
    
    @Test("최대 깊이 초과 에러 메시지 검증")
    func testMaxDepthExceededErrorMessage() throws {
        var detector = CircularReferenceDetector()
        
        // 최대 깊이까지 도달
        for i in 1...CircularReferenceDetector.maxDepth {
            try detector.enter(typeName: "Type\(i)")
        }
        
        do {
            try detector.enter(typeName: "Type6")
            Issue.record("최대 깊이 초과 에러가 발생해야 합니다")
        } catch let error as CircularReferenceError {
            let message = error.description
            #expect(message.contains("최대 재귀 깊이를 초과"))
            #expect(message.contains("해결 방법"))
        }
    }
    
    @Test("동일한 타입을 순차적으로 방문")
    func testSequentialVisitsOfSameType() throws {
        var detector = CircularReferenceDetector()
        
        // 첫 번째 방문
        try detector.enter(typeName: "User")
        detector.exit(typeName: "User")
        
        // 두 번째 방문 (가능해야 함)
        #expect(detector.canVisit(typeName: "User"))
        try detector.enter(typeName: "User")
        detector.exit(typeName: "User")
        
        #expect(detector.depth == 0)
    }
    
    @Test("현재 경로 추적")
    func testCurrentPathTracking() throws {
        var detector = CircularReferenceDetector()
        
        try detector.enter(typeName: "A")
        #expect(detector.currentPath == ["A"])
        
        try detector.enter(typeName: "B")
        #expect(detector.currentPath.contains("A"))
        #expect(detector.currentPath.contains("B"))
        
        try detector.enter(typeName: "C")
        #expect(detector.currentPath.count == 3)
        
        detector.exit(typeName: "C")
        #expect(detector.currentPath.count == 2)
        #expect(!detector.currentPath.contains("C"))
    }
}
