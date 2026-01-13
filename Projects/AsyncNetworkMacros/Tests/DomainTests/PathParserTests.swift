//
//  PathParserTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import Testing

    @Suite("PathParser Tests")
    struct PathParserTests {
        let parser = PathParser()

        // MARK: - extractPlaceholders Tests

        @Test("플레이스홀더 추출 - 단일")
        func extractSinglePlaceholder() {
            let placeholders = parser.extractPlaceholders(from: "/posts/{id}")
            #expect(placeholders == ["id"])
        }

        @Test("플레이스홀더 추출 - 다중")
        func extractMultiplePlaceholders() {
            let placeholders = parser.extractPlaceholders(
                from: "/posts/{id}/comments/{commentId}"
            )
            #expect(placeholders == ["id", "commentId"])
        }

        @Test("플레이스홀더 추출 - 선택적 파라미터")
        func extractOptionalPlaceholder() {
            let placeholders = parser.extractPlaceholders(from: "/api/{version?}/posts")
            #expect(placeholders == ["version"])
        }

        @Test("플레이스홀더 추출 - 없음")
        func extractNoPlaceholders() {
            let placeholders = parser.extractPlaceholders(from: "/posts")
            #expect(placeholders.isEmpty)
        }

        // MARK: - extractOptionalParameters Tests

        @Test("선택적 파라미터 추출")
        func testExtractOptionalParameters() {
            let optionals = parser.extractOptionalParameters(from: "/api/{version?}/posts/{id}")
            #expect(optionals == ["version"])
        }

        @Test("선택적 파라미터 추출 - 다중")
        func extractMultipleOptionalParameters() {
            let optionals = parser.extractOptionalParameters(
                from: "/api/{version?}/{resource?}/{id}"
            )
            #expect(optionals == Set(["version", "resource"]))
        }

        @Test("선택적 파라미터 추출 - 없음")
        func extractNoOptionalParameters() {
            let optionals = parser.extractOptionalParameters(from: "/posts/{id}")
            #expect(optionals.isEmpty)
        }

        // MARK: - normalize Tests

        @Test("경로 정규화")
        func normalizePath() {
            let normalized = parser.normalize("/posts/{id?}")
            #expect(normalized == "/posts/{id}")
        }

        @Test("경로 정규화 - 다중")
        func normalizeMultiplePath() {
            let normalized = parser.normalize("/api/{version?}/{resource?}/{id}")
            #expect(normalized == "/api/{version}/{resource}/{id}")
        }

        @Test("경로 정규화 - 이미 정규화됨")
        func normalizeAlreadyNormalizedPath() {
            let normalized = parser.normalize("/posts/{id}")
            #expect(normalized == "/posts/{id}")
        }

        // MARK: - areSimilar Tests

        @Test("유사 이름 비교 - 정확히 일치")
        func areSimilarExactMatch() {
            #expect(parser.areSimilar("id", "id"))
            #expect(parser.areSimilar("userId", "userId"))
        }

        @Test("유사 이름 비교 - 대소문자 무시")
        func areSimilarCaseInsensitive() {
            #expect(parser.areSimilar("userId", "UserId"))
            #expect(parser.areSimilar("ID", "id"))
        }

        @Test("유사 이름 비교 - 복수형")
        func areSimilarPlural() {
            #expect(parser.areSimilar("id", "ids"))
            #expect(parser.areSimilar("user", "users"))
        }

        @Test("유사 이름 비교 - 언더스코어 vs 캐멀케이스")
        func areSimilarUnderscoreVsCamelCase() {
            #expect(parser.areSimilar("user_id", "userId"))
            #expect(parser.areSimilar("post_title", "postTitle"))
        }

        @Test("유사 이름 비교 - 다름")
        func areSimilarDifferent() {
            #expect(!parser.areSimilar("id", "postId"))
            #expect(!parser.areSimilar("user", "post"))
        }
    }

#endif // os(macOS)
