//
//  QueryParameterArrayTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/02/02.
//

// swiftlint:disable file_length type_body_length

@testable import AsyncNetworkCore
import Foundation
import Testing

@Suite("QueryParameter Array Tests")
struct QueryParameterArrayTests {
    @Test("QueryParameter - Optional 배열 파라미터 (여러 개)")
    func optionalArrayWithMultipleElements() throws {
        // Given
        struct TestRequestWithArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/products"
            var method: HTTPMethod = .get

            @QueryParameter var tags: [String]?

            init(tags: [String]? = nil) {
                self.tags = tags
            }
        }

        let request = TestRequestWithArray(
            tags: ["electronics", "sale", "featured", "popular"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 배열의 각 요소가 개별 쿼리 파라미터로 변환되어야 함
        let tagItems = queryItems?.filter { $0.name == "tags" }
        #expect(tagItems?.count == 4)
        #expect(tagItems?.contains(where: { $0.value == "electronics" }) == true)
        #expect(tagItems?.contains(where: { $0.value == "sale" }) == true)
        #expect(tagItems?.contains(where: { $0.value == "featured" }) == true)
        #expect(tagItems?.contains(where: { $0.value == "popular" }) == true)

        // URL 형태 확인 (tags=electronics&tags=sale&...)
        #expect(urlString.contains("tags=electronics"))
        #expect(urlString.contains("tags=sale"))
        #expect(urlString.contains("tags=featured"))
        #expect(urlString.contains("tags=popular"))

        // JSON 배열 형태가 아니어야 함
        #expect(!urlString.contains("%5B")) // [ 인코딩
        #expect(!urlString.contains("%5D")) // ] 인코딩
    }

    @Test("QueryParameter - Optional 배열 파라미터 (빈 배열)")
    func optionalArrayWithEmptyArray() throws {
        // Given
        struct TestRequestWithArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/items"
            var method: HTTPMethod = .get

            @QueryParameter var tags: [String]?

            init(tags: [String]? = nil) {
                self.tags = tags
            }
        }

        let request = TestRequestWithArray(tags: [])

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 빈 배열은 쿼리 파라미터가 없어야 함
        #expect(queryItems == nil || queryItems?.isEmpty == true)
    }

    @Test("QueryParameter - Optional 배열 파라미터 (nil)")
    func optionalArrayWithNil() throws {
        // Given
        struct TestRequestWithArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/items"
            var method: HTTPMethod = .get

            @QueryParameter var categories: [String]?

            init(categories: [String]? = nil) {
                self.categories = categories
            }
        }

        let request = TestRequestWithArray(categories: nil)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // nil 배열은 쿼리 파라미터가 없어야 함
        #expect(queryItems == nil || queryItems?.isEmpty == true)
    }

    @Test("QueryParameter - Optional 배열 파라미터 (단일 요소)")
    func optionalArrayWithSingleElement() throws {
        // Given
        struct TestRequestWithArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/items"
            var method: HTTPMethod = .get

            @QueryParameter var ids: [Int]?

            init(ids: [Int]? = nil) {
                self.ids = ids
            }
        }

        let request = TestRequestWithArray(ids: [42])

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 단일 요소도 배열 형태로 처리
        let idItems = queryItems?.filter { $0.name == "ids" }
        #expect(idItems?.count == 1)
        #expect(idItems?.first?.value == "42")
    }

    @Test("QueryParameter - Non-optional 배열 파라미터")
    func nonOptionalArray() throws {
        // Given
        struct TestRequestWithArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/search"
            var method: HTTPMethod = .get

            @QueryParameter var filters: [String]

            init(filters: [String]) {
                self.filters = filters
            }
        }

        let request = TestRequestWithArray(filters: ["active", "verified", "premium"])

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 각 요소가 개별 파라미터로 추가되어야 함
        let filterItems = queryItems?.filter { $0.name == "filters" }
        #expect(filterItems?.count == 3)
        #expect(filterItems?.contains(where: { $0.value == "active" }) == true)
        #expect(filterItems?.contains(where: { $0.value == "verified" }) == true)
        #expect(filterItems?.contains(where: { $0.value == "premium" }) == true)
    }

    @Test("QueryParameter - 커스텀 키와 배열 조합")
    func customKeyWithArray() throws {
        // Given
        struct TestRequestWithArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/products"
            var method: HTTPMethod = .get

            @QueryParameter(key: "filter_id") var filterIds: [Int]?

            init(filterIds: [Int]? = nil) {
                self.filterIds = filterIds
            }
        }

        let request = TestRequestWithArray(
            filterIds: [101, 102, 103, 104]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 커스텀 키로 변환되어야 함
        let filterItems = queryItems?.filter { $0.name == "filter_id" }
        #expect(filterItems?.count == 4)

        // URL 형태 확인 (filter_id=101&filter_id=102&...)
        #expect(urlString.contains("filter_id=101"))
        #expect(urlString.contains("filter_id=102"))
        #expect(urlString.contains("filter_id=103"))
        #expect(urlString.contains("filter_id=104"))

        // 원래 프로퍼티 이름은 사용되지 않아야 함
        #expect(!urlString.contains("filterIds"))
    }

    @Test("QueryParameter - 배열과 일반 파라미터 혼합")
    func arrayWithOtherParameters() throws {
        // Given
        struct TestRequestMixed: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/products"
            var method: HTTPMethod = .get

            @QueryParameter var page: Int?
            @QueryParameter var limit: Int?
            @QueryParameter var sort: String?
            @QueryParameter var tags: [String]?

            init(page: Int? = nil, limit: Int? = nil, sort: String? = nil, tags: [String]? = nil) {
                self.page = page
                self.limit = limit
                self.sort = sort
                self.tags = tags
            }
        }

        let request = TestRequestMixed(
            page: 1,
            limit: 20,
            sort: "price_asc",
            tags: ["electronics", "sale", "new", "featured"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 일반 파라미터 확인
        #expect(queryItems?.contains(where: { $0.name == "page" && $0.value == "1" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "limit" && $0.value == "20" }) == true)

        // 배열 파라미터 확인
        let tagItems = queryItems?.filter { $0.name == "tags" }
        #expect(tagItems?.count == 4)
        #expect(tagItems?.contains(where: { $0.value == "electronics" }) == true)
        #expect(tagItems?.contains(where: { $0.value == "sale" }) == true)
        #expect(tagItems?.contains(where: { $0.value == "new" }) == true)
        #expect(tagItems?.contains(where: { $0.value == "featured" }) == true)

        // URL 형태 확인
        #expect(urlString.contains("page=1"))
        #expect(urlString.contains("limit=20"))
        #expect(urlString.contains("tags=electronics"))
        #expect(urlString.contains("tags=sale"))
    }

    @Test("QueryParameter - 정수 배열")
    func integerArray() throws {
        // Given
        struct TestRequestWithIntArray: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/items"
            var method: HTTPMethod = .get

            @QueryParameter var productIds: [Int]?

            init(productIds: [Int]? = nil) {
                self.productIds = productIds
            }
        }

        let request = TestRequestWithIntArray(productIds: [1, 2, 3, 5, 8])

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 각 정수가 문자열로 변환되어 개별 파라미터로 추가되어야 함
        let productIdItems = queryItems?.filter { $0.name == "productIds" }
        #expect(productIdItems?.count == 5)
        #expect(productIdItems?.contains(where: { $0.value == "1" }) == true)
        #expect(productIdItems?.contains(where: { $0.value == "2" }) == true)
        #expect(productIdItems?.contains(where: { $0.value == "3" }) == true)
        #expect(productIdItems?.contains(where: { $0.value == "5" }) == true)
        #expect(productIdItems?.contains(where: { $0.value == "8" }) == true)
    }

    @Test("QueryParameter - 복잡한 요청 구조 - 요청 생성")
    func complexRequestStructure() throws {
        // Given - 복잡한 요청 구조 테스트
        struct GetProductsRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/api/v1/products"
            var method: HTTPMethod = .get

            @QueryParameter var page: Int?
            @QueryParameter var limit: Int?
            @QueryParameter var sort: String?
            @QueryParameter var search: String?
            @QueryParameter var status: String?
            @QueryParameter(key: "category_id") var categoryIds: [String]?

            init(
                page: Int? = nil,
                limit: Int? = nil,
                sort: String? = nil,
                search: String? = nil,
                status: String? = nil,
                categoryIds: [String]? = nil
            ) {
                self.page = page
                self.limit = limit
                self.sort = sort
                self.search = search
                self.status = status
                self.categoryIds = categoryIds
            }
        }

        let request = GetProductsRequest(
            page: 1,
            limit: 50,
            search: "laptop",
            categoryIds: ["cat_101", "cat_102", "cat_103", "cat_104", "cat_105", "cat_106", "cat_107", "cat_108"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 기본 파라미터 확인
        #expect(queryItems?.contains(where: { $0.name == "page" && $0.value == "1" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "search" && $0.value == "laptop" }) == true)

        // 배열이 개별 파라미터로 변환되었는지 확인
        let categoryItems = queryItems?.filter { $0.name == "category_id" }
        #expect(categoryItems?.count == 8)
    }

    @Test("QueryParameter - 복잡한 요청 구조 - URL 형식 검증")
    func complexRequestURLFormat() throws {
        // Given
        struct GetProductsRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/api/v1/products"
            var method: HTTPMethod = .get

            @QueryParameter(key: "category_id") var categoryIds: [String]?

            init(categoryIds: [String]? = nil) {
                self.categoryIds = categoryIds
            }
        }

        let request = GetProductsRequest(
            categoryIds: ["cat_101", "cat_102", "cat_103", "cat_104", "cat_105", "cat_106", "cat_107", "cat_108"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        // URL 형태가 올바른지 확인 (category_id=cat_101&category_id=cat_102&...)
        #expect(urlString.contains("category_id=cat_101"))
        #expect(urlString.contains("category_id=cat_102"))
        #expect(urlString.contains("category_id=cat_103"))
        #expect(urlString.contains("category_id=cat_104"))
        #expect(urlString.contains("category_id=cat_105"))
        #expect(urlString.contains("category_id=cat_106"))
        #expect(urlString.contains("category_id=cat_107"))
        #expect(urlString.contains("category_id=cat_108"))

        // category_id가 JSON 배열 형태가 아니어야 함
        #expect(!urlString.contains("category_id=%5B"))

        // category_id가 개별 파라미터로 분리되어 있는지 확인
        let categoryIdPattern = "category_id=cat_101&category_id=cat_102"
        #expect(urlString.contains(categoryIdPattern))

        print("✅ Generated URL: \(urlString)")
    }
}
