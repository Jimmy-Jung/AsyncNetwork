//
//  QueryParameterAdvancedTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

@Suite("QueryParameter Advanced Tests")
struct QueryParameterAdvancedTests {
    @Test("QueryParameter - Property 선언에서 key 지정 (Optional)")
    func customKeyInPropertyDeclaration() throws {
        // Given
        struct TestRequestWithKeyInDeclaration: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/test"
            var method: HTTPMethod = .get

            @QueryParameter(key: "user_id") var userId: Int?
            @QueryParameter(key: "max_results") var maxResults: Int?

            init(userId: Int? = nil, maxResults: Int? = nil) {
                self.userId = userId
                self.maxResults = maxResults
            }
        }

        var request = TestRequestWithKeyInDeclaration()
        request.userId = 42
        request.maxResults = 100

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 커스텀 키로 변환되어야 함
        #expect(queryItems?.contains(where: { $0.name == "user_id" && $0.value == "42" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "max_results" && $0.value == "100" }) == true)

        // 원래 프로퍼티 이름은 사용되지 않음
        #expect(queryItems?.contains(where: { $0.name == "userId" }) == false)
        #expect(queryItems?.contains(where: { $0.name == "maxResults" }) == false)
    }

    @Test("QueryParameter - Property 선언에서 key 지정, nil 값은 생략")
    func customKeyInPropertyDeclarationWithNil() throws {
        // Given
        struct TestRequestWithKeyInDeclaration: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/test"
            var method: HTTPMethod = .get

            @QueryParameter(key: "user_id") var userId: Int?
            @QueryParameter(key: "max_results") var maxResults: Int?

            init() {}
        }

        let request = TestRequestWithKeyInDeclaration()

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // nil 값은 추가되지 않아야 함
        #expect(queryItems == nil || queryItems?.isEmpty == true)
    }

    @Test("QueryParameter - Non-optional에 property 선언에서 key 지정")
    func nonOptionalWithCustomKeyInPropertyDeclaration() throws {
        // Given
        struct TestRequestWithNonOptionalKey: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/test"
            var method: HTTPMethod = .get

            @QueryParameter(key: "user_id") var userId: Int
            @QueryParameter(key: "is_active") var isActive: Bool

            init(userId: Int, isActive: Bool) {
                self.userId = userId
                self.isActive = isActive
            }
        }

        let request = TestRequestWithNonOptionalKey(userId: 123, isActive: true)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 커스텀 키로 변환되어야 함
        #expect(queryItems?.contains(where: { $0.name == "user_id" && $0.value == "123" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "is_active" && $0.value == "true" }) == true)

        // 원래 프로퍼티 이름은 사용되지 않음
        #expect(queryItems?.contains(where: { $0.name == "userId" }) == false)
        #expect(queryItems?.contains(where: { $0.name == "isActive" }) == false)
    }

    @Test("QueryParameter - Non-optional과 Optional 모두 property 선언에서 key 지정")
    func mixedTypesWithCustomKeyInPropertyDeclaration() throws {
        // Given
        struct TestRequestMixedTypes: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/search"
            var method: HTTPMethod = .get

            @QueryParameter(key: "q") var query: String
            @QueryParameter(key: "page") var page: Int
            @QueryParameter(key: "_limit") var limit: Int?
            @QueryParameter(key: "sort_by") var sortBy: String?

            init(query: String, page: Int, limit: Int? = nil, sortBy: String? = nil) {
                self.query = query
                self.page = page
                self.limit = limit
                self.sortBy = sortBy
            }
        }

        let request = TestRequestMixedTypes(query: "swift", page: 1, limit: 50, sortBy: nil)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // Non-optional 값들은 항상 존재
        #expect(queryItems?.contains(where: { $0.name == "q" && $0.value == "swift" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "page" && $0.value == "1" }) == true)

        // Optional 값 중 설정된 것만 존재
        #expect(queryItems?.contains(where: { $0.name == "_limit" && $0.value == "50" }) == true)

        // nil인 Optional은 존재하지 않음
        #expect(queryItems?.contains(where: { $0.name == "sort_by" }) == false)
    }

    @Test("QueryParameter - 커스텀 타입 (DefaultInitializable 구현)")
    func customTypeWithDefaultInitializable() throws {
        // Given
        enum SortOrder: String, Sendable, DefaultInitializable {
            case asc
            case desc

            static var defaultValue: SortOrder { .asc }
        }

        struct TestRequestWithEnum: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/items"
            var method: HTTPMethod = .get

            @QueryParameter(key: "sort") var sortOrder: SortOrder

            init(sortOrder: SortOrder) {
                self.sortOrder = sortOrder
            }
        }

        let request = TestRequestWithEnum(sortOrder: .desc)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // Enum의 rawValue가 사용되어야 함
        #expect(queryItems?.contains(where: { $0.name == "sort" && $0.value == "desc" }) == true)
    }

    @Test("QueryParameter - 커스텀 타입 Fallback (직접 초기화)")
    func customTypeWithDirectInitialization() throws {
        // Given
        struct CustomFilter: Sendable {
            let category: String
            let minPrice: Int
        }

        struct TestRequestWithCustomType: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/products"
            var method: HTTPMethod = .get

            @QueryParameter var filter: CustomFilter

            init(filter: CustomFilter) {
                // Property wrapper를 직접 초기화 (커스텀 키 지정)
                _filter = QueryParameter(wrappedValue: filter, key: "filter_data")
            }
        }

        let filter = CustomFilter(category: "electronics", minPrice: 100)
        let request = TestRequestWithCustomType(filter: filter)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // filter_data 키로 CustomFilter 객체의 description이 사용됨
        #expect(queryItems?.contains(where: { $0.name == "filter_data" }) == true)
    }
}
