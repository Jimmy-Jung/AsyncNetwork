//
//  PathParser.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

/// 경로 파싱 전담 클래스
public struct PathParser {
    public init() {}

    /// 경로에서 플레이스홀더 추출
    ///
    /// - Parameter path: "/posts/{id}/comments/{commentId}"
    /// - Returns: ["id", "commentId"]
    ///
    /// ## 예시
    /// ```swift
    /// let parser = PathParser()
    /// let placeholders = parser.extractPlaceholders(from: "/posts/{id}")
    /// // placeholders == ["id"]
    /// ```
    ///
    /// ## 유효한 플레이스홀더 패턴
    /// - `{id}`: 필수 파라미터
    /// - `{userId}`: 캐멀케이스
    /// - `{user_id}`: 언더스코어
    /// - `{id?}`: 선택적 파라미터
    ///
    /// ## 무효한 패턴 (무시됨)
    /// - `{}`: 빈 플레이스홀더
    /// - `{123}`: 숫자로 시작
    /// - `{my-id}`: 하이픈 포함
    public func extractPlaceholders(from path: String) -> [String] {
        var placeholders: [String] = []
        var current = ""
        var inPlaceholder = false

        for char in path {
            if char == "{" {
                inPlaceholder = true
                current = ""
            } else if char == "}" {
                if inPlaceholder, !current.isEmpty {
                    // {id?} 형태에서 ? 제거
                    let cleaned = current.replacingOccurrences(of: "?", with: "")
                    
                    // 유효한 식별자인지 검증
                    if isValidIdentifier(cleaned) {
                        placeholders.append(cleaned)
                    }
                }
                inPlaceholder = false
            } else if inPlaceholder {
                current.append(char)
            }
        }

        return placeholders
    }
    
    /// Swift 식별자로 유효한지 검증
    /// - Parameter name: 검증할 이름
    /// - Returns: 유효한 식별자 여부
    ///
    /// Swift 식별자 규칙:
    /// - 첫 글자: 알파벳 또는 언더스코어
    /// - 이후 글자: 알파벳, 숫자, 언더스코어
    private func isValidIdentifier(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        
        let first = name.first!
        guard first.isLetter || first == "_" else {
            return false
        }
        
        for char in name.dropFirst() {
            guard char.isLetter || char.isNumber || char == "_" else {
                return false
            }
        }
        
        return true
    }

    /// 선택적 파라미터 추출
    ///
    /// - Parameter path: "/posts/{id?}"
    /// - Returns: ["id"]
    ///
    /// ## 예시
    /// ```swift
    /// let parser = PathParser()
    /// let optionals = parser.extractOptionalParameters(from: "/api/{version?}/posts")
    /// // optionals == ["version"]
    /// ```
    public func extractOptionalParameters(from path: String) -> Set<String> {
        var optionals = Set<String>()
        var current = ""
        var inPlaceholder = false

        for char in path {
            if char == "{" {
                inPlaceholder = true
                current = ""
            } else if char == "}" {
                if inPlaceholder && current.hasSuffix("?") {
                    let name = String(current.dropLast())
                    optionals.insert(name)
                }
                inPlaceholder = false
            } else if inPlaceholder {
                current.append(char)
            }
        }

        return optionals
    }

    /// 경로 정규화 (? 제거)
    ///
    /// - Parameter path: "/posts/{id?}"
    /// - Returns: "/posts/{id}"
    ///
    /// ## 예시
    /// ```swift
    /// let parser = PathParser()
    /// let normalized = parser.normalize("/api/{version?}/{resource?}")
    /// // normalized == "/api/{version}/{resource}"
    /// ```
    public func normalize(_ path: String) -> String {
        path.replacingOccurrences(of: "?}", with: "}")
    }

    /// 두 이름이 유사한지 확인
    ///
    /// 다음 경우 유사하다고 판단:
    /// 1. 정확히 일치 (대소문자 무시)
    /// 2. 복수형 차이 (id vs ids)
    /// 3. 언더스코어 vs 캐멀케이스 (user_id vs userId)
    ///
    /// - Parameters:
    ///   - name1: 첫 번째 이름
    ///   - name2: 두 번째 이름
    /// - Returns: 유사 여부
    public func areSimilar(_ name1: String, _ name2: String) -> Bool {
        let lower1 = name1.lowercased()
        let lower2 = name2.lowercased()

        // 1. 정확히 일치
        if lower1 == lower2 {
            return true
        }

        // 2. 복수형 체크 (ids <-> id, users <-> user)
        if lower1 == lower2 + "s" || lower2 == lower1 + "s" {
            return true
        }

        // 3. 언더스코어 vs 캐멀케이스 (user_id <-> userId)
        let normalized1 = lower1.replacingOccurrences(of: "_", with: "")
        let normalized2 = lower2.replacingOccurrences(of: "_", with: "")
        if normalized1 == normalized2 {
            return true
        }

        return false
    }
}
