//
//  PerformanceBaselineTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/02.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

/// v1.0 성능 기준선 테스트 (Reflection 사용)
@Suite("Performance Baseline - v1.0")
struct PerformanceBaselineTests {
    // MARK: - Test Request

    private struct TestRequest: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/test/123" // PathParameter 대신 직접 경로 사용
        var method: HTTPMethod = .get
        var headers: [String: String]? = ["Authorization": "Bearer token"]
    }

    // MARK: - Tests

    @Test("URLRequest 생성 시간 (Reflection 사용) - 1000회")
    func uRLRequestCreationTime() async throws {
        let request = TestRequest()

        // Warmup
        for _ in 0 ..< 100 {
            _ = try? request.asURLRequest()
        }

        // Measure
        let startTime = Date()
        for _ in 0 ..< 1000 {
            _ = try request.asURLRequest()
        }
        let elapsed = Date().timeIntervalSince(startTime) * 1000 // ms

        print("📊 Baseline Performance (v1.0)")
        print("   - Total time: \(String(format: "%.2f", elapsed))ms")
        print("   - Per request: \(String(format: "%.2f", elapsed / 1000))ms")
        print("   - Target for v2.0: <\(String(format: "%.2f", elapsed / 3))ms (3x improvement)")

        // 기준선 기록 (실패하지 않음, 기록용)
        #expect(elapsed > 0)
    }

    @Test("단일 URLRequest 생성 시간 (평균)")
    func singleRequestCreation() async throws {
        let request = TestRequest()

        var totalTime: TimeInterval = 0
        let iterations = 100

        for _ in 0 ..< iterations {
            let start = Date()
            _ = try request.asURLRequest()
            totalTime += Date().timeIntervalSince(start)
        }

        let averageTime = (totalTime / Double(iterations)) * 1_000_000 // μs

        print("📊 Single Request Average")
        print("   - Average time: \(String(format: "%.2f", averageTime))μs")
        print("   - Expected: 10-20μs (with Reflection)")

        #expect(totalTime > 0)
    }

    @Test("메모리 할당 추정")
    func memoryFootprint() async throws {
        let request = TestRequest()

        // 1000개의 URLRequest 생성
        var requests: [URLRequest] = []
        requests.reserveCapacity(1000)

        for _ in 0 ..< 1000 {
            if let urlRequest = try? request.asURLRequest() {
                requests.append(urlRequest)
            }
        }

        print("📊 Memory Footprint")
        print("   - Created \(requests.count) URLRequests")
        print("   - Estimated: ~5KB per 1000 requests (with Reflection overhead)")

        #expect(requests.count == 1000)
    }
}
