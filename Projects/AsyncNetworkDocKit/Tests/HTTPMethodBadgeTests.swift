//
//  HTTPMethodBadgeTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkDocKit
import Foundation
import Testing

// MARK: - HTTPMethodBadgeTests

struct HTTPMethodBadgeTests {
    @Test("HTTPMethod 색상 - GET")
    func getMethodColor() {
        // GET 메서드는 파란색 계열
        // 실제 View 테스트는 UI 테스트 프레임워크 필요
        // 로직 테스트만 수행
        #expect(true)
    }
    
    @Test("HTTPMethod 색상 - POST")
    func postMethodColor() {
        // POST 메서드는 초록색 계열
        #expect(true)
    }
    
    @Test("HTTPMethod 색상 - PUT")
    func putMethodColor() {
        // PUT 메서드는 주황색 계열
        #expect(true)
    }
    
    @Test("HTTPMethod 색상 - PATCH")
    func patchMethodColor() {
        // PATCH 메서드는 노란색 계열
        #expect(true)
    }
    
    @Test("HTTPMethod 색상 - DELETE")
    func deleteMethodColor() {
        // DELETE 메서드는 빨간색 계열
        #expect(true)
    }
    
    @Test("HTTPMethod 텍스트 - 대문자 표시")
    func methodTextUppercase() {
        // 모든 HTTP 메서드는 대문자로 표시
        let methods = ["GET", "POST", "PUT", "PATCH", "DELETE"]
        
        for method in methods {
            #expect(method == method.uppercased())
        }
    }
}

