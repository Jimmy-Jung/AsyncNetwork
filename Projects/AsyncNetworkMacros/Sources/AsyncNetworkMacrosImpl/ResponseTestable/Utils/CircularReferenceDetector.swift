//
//  CircularReferenceDetector.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/02/03.
//

import Foundation

/// 순환 참조 감지 및 재귀 깊이 제한
///
/// 타입 간의 순환 참조를 감지하고, 무한 재귀를 방지합니다.
/// 예: `User` → `Post` → `User` (순환 참조)
public struct CircularReferenceDetector {
    /// 최대 재귀 깊이 (기본값: 5)
    public static let maxDepth = 5
    
    private var visitedTypes: Set<String>
    private var currentDepth: Int
    
    /// 초기화
    public init() {
        self.visitedTypes = []
        self.currentDepth = 0
    }
    
    /// 타입 방문 시도
    /// - Parameter typeName: 방문할 타입 이름
    /// - Returns: 방문 가능 여부 (순환 참조가 없고 깊이 제한 내인 경우 true)
    public func canVisit(typeName: String) -> Bool {
        // 깊이 제한 체크
        guard currentDepth < Self.maxDepth else {
            return false
        }
        
        // 순환 참조 체크
        guard !visitedTypes.contains(typeName) else {
            return false
        }
        
        return true
    }
    
    /// 타입 방문 시작
    /// - Parameter typeName: 방문할 타입 이름
    /// - Throws: 순환 참조 또는 깊이 초과 시 에러
    public mutating func enter(typeName: String) throws {
        guard canVisit(typeName: typeName) else {
            if visitedTypes.contains(typeName) {
                throw CircularReferenceError.circularReference(
                    typeName: typeName,
                    path: Array(visitedTypes)
                )
            } else {
                throw CircularReferenceError.maxDepthExceeded(
                    depth: currentDepth,
                    maxDepth: Self.maxDepth
                )
            }
        }
        
        visitedTypes.insert(typeName)
        currentDepth += 1
    }
    
    /// 타입 방문 종료
    /// - Parameter typeName: 방문 종료할 타입 이름
    public mutating func exit(typeName: String) {
        visitedTypes.remove(typeName)
        currentDepth -= 1
    }
    
    /// 현재 방문 경로 조회
    public var currentPath: [String] {
        Array(visitedTypes)
    }
    
    /// 현재 깊이 조회
    public var depth: Int {
        currentDepth
    }
}

// MARK: - Error Types

/// 순환 참조 관련 에러
public enum CircularReferenceError: Error, CustomStringConvertible {
    case circularReference(typeName: String, path: [String])
    case maxDepthExceeded(depth: Int, maxDepth: Int)
    
    public var description: String {
        switch self {
        case .circularReference(let typeName, let path):
            let pathString = path.joined(separator: " → ")
            return """
            순환 참조가 감지되었습니다: \(typeName)
            참조 경로: \(pathString) → \(typeName)
            
            해결 방법:
            1. 순환 참조를 제거하거나
            2. 옵셔널 타입을 사용하여 참조를 끊으세요
            """
            
        case .maxDepthExceeded(let depth, let maxDepth):
            return """
            최대 재귀 깊이를 초과했습니다: \(depth) > \(maxDepth)
            
            해결 방법:
            1. 타입 계층 구조를 단순화하거나
            2. 옵셔널 타입을 사용하여 깊이를 줄이세요
            """
        }
    }
}
