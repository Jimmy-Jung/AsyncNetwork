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
            var path: String = "/curated-studies"
            var method: HTTPMethod = .get

            @QueryParameter var middleUnitIds: [String]?

            init(middleUnitIds: [String]? = nil) {
                self.middleUnitIds = middleUnitIds
            }
        }

        let request = TestRequestWithArray(
            middleUnitIds: ["1111", "1112", "1121", "1122"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 배열의 각 요소가 개별 쿼리 파라미터로 변환되어야 함
        let middleUnitIdItems = queryItems?.filter { $0.name == "middleUnitIds" }
        #expect(middleUnitIdItems?.count == 4)
        #expect(middleUnitIdItems?.contains(where: { $0.value == "1111" }) == true)
        #expect(middleUnitIdItems?.contains(where: { $0.value == "1112" }) == true)
        #expect(middleUnitIdItems?.contains(where: { $0.value == "1121" }) == true)
        #expect(middleUnitIdItems?.contains(where: { $0.value == "1122" }) == true)

        // URL 형태 확인 (middleUnitIds=1111&middleUnitIds=1112&...)
        #expect(urlString.contains("middleUnitIds=1111"))
        #expect(urlString.contains("middleUnitIds=1112"))
        #expect(urlString.contains("middleUnitIds=1121"))
        #expect(urlString.contains("middleUnitIds=1122"))

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
            var path: String = "/application/v1/curated-studies"
            var method: HTTPMethod = .get

            @QueryParameter(key: "middleUnitId") var middleUnitIds: [String]?

            init(middleUnitIds: [String]? = nil) {
                self.middleUnitIds = middleUnitIds
            }
        }

        let request = TestRequestWithArray(
            middleUnitIds: ["1111", "1112", "1121", "1122"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 커스텀 키로 변환되어야 함
        let unitIdItems = queryItems?.filter { $0.name == "middleUnitId" }
        #expect(unitIdItems?.count == 4)

        // URL 형태 확인 (middleUnitId=1111&middleUnitId=1112&...)
        #expect(urlString.contains("middleUnitId=1111"))
        #expect(urlString.contains("middleUnitId=1112"))
        #expect(urlString.contains("middleUnitId=1121"))
        #expect(urlString.contains("middleUnitId=1122"))

        // 원래 프로퍼티 이름은 사용되지 않아야 함
        #expect(!urlString.contains("middleUnitIds"))
    }

    @Test("QueryParameter - 배열과 일반 파라미터 혼합")
    func arrayWithOtherParameters() throws {
        // Given
        struct TestRequestMixed: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/curated-studies"
            var method: HTTPMethod = .get

            @QueryParameter var size: Int?
            @QueryParameter var orders: String?
            @QueryParameter var userId: String?
            @QueryParameter var middleUnitIds: [String]?

            init(size: Int? = nil, orders: String? = nil, userId: String? = nil, middleUnitIds: [String]? = nil) {
                self.size = size
                self.orders = orders
                self.userId = userId
                self.middleUnitIds = middleUnitIds
            }
        }

        let request = TestRequestMixed(
            size: 100,
            orders: "[{\"_id\":0}]",
            userId: "65960afb136d98c235ec0e11",
            middleUnitIds: ["1111", "1112", "1121", "1122"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 일반 파라미터 확인
        #expect(queryItems?.contains(where: { $0.name == "size" && $0.value == "100" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "userId" && $0.value == "65960afb136d98c235ec0e11" }) == true)

        // 배열 파라미터 확인
        let unitIdItems = queryItems?.filter { $0.name == "middleUnitIds" }
        #expect(unitIdItems?.count == 4)
        #expect(unitIdItems?.contains(where: { $0.value == "1111" }) == true)
        #expect(unitIdItems?.contains(where: { $0.value == "1112" }) == true)
        #expect(unitIdItems?.contains(where: { $0.value == "1121" }) == true)
        #expect(unitIdItems?.contains(where: { $0.value == "1122" }) == true)

        // URL 형태 확인
        #expect(urlString.contains("size=100"))
        #expect(urlString.contains("userId=65960afb136d98c235ec0e11"))
        #expect(urlString.contains("middleUnitIds=1111"))
        #expect(urlString.contains("middleUnitIds=1112"))
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

    @Test("QueryParameter - 실제 사용 케이스 재현 - 요청 생성")
    func realWorldUseCaseRequest() throws {
        // Given - 사용자의 실제 요청 구조 재현
        struct GetCuratedStudiesRequest: APIRequest {
            var baseURLString: String = "https://dev.an2.api.slc.susimdal.com"
            var path: String = "/application/v1/curated-studies"
            var method: HTTPMethod = .get

            @QueryParameter var size: Int?
            @QueryParameter var orders: String?
            @QueryParameter var nextToken: String?
            @QueryParameter var userId: String?
            @QueryParameter var semesterId: String?
            @QueryParameter(key: "middleUnitId") var middleUnitIds: [String]?

            init(
                size: Int? = nil,
                orders: String? = nil,
                nextToken: String? = nil,
                userId: String? = nil,
                semesterId: String? = nil,
                middleUnitIds: [String]? = nil
            ) {
                self.size = size
                self.orders = orders
                self.nextToken = nextToken
                self.userId = userId
                self.semesterId = semesterId
                self.middleUnitIds = middleUnitIds
            }
        }

        let request = GetCuratedStudiesRequest(
            size: 100,
            orders: "[{\"_id\":0}]",
            userId: "65960afb136d98c235ec0e11",
            middleUnitIds: ["1111", "1112", "1121", "1122", "1131", "1132", "1141", "1142"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 기본 파라미터 확인
        #expect(queryItems?.contains(where: { $0.name == "size" && $0.value == "100" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "userId" && $0.value == "65960afb136d98c235ec0e11" }) == true)

        // 배열이 개별 파라미터로 변환되었는지 확인
        let unitIdItems = queryItems?.filter { $0.name == "middleUnitId" }
        #expect(unitIdItems?.count == 8)
    }

    @Test("QueryParameter - 실제 사용 케이스 재현 - URL 형식 검증")
    func realWorldUseCaseURLFormat() throws {
        // Given
        struct GetCuratedStudiesRequest: APIRequest {
            var baseURLString: String = "https://dev.an2.api.slc.susimdal.com"
            var path: String = "/application/v1/curated-studies"
            var method: HTTPMethod = .get

            @QueryParameter(key: "middleUnitId") var middleUnitIds: [String]?

            init(middleUnitIds: [String]? = nil) {
                self.middleUnitIds = middleUnitIds
            }
        }

        let request = GetCuratedStudiesRequest(
            middleUnitIds: ["1111", "1112", "1121", "1122", "1131", "1132", "1141", "1142"]
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        // URL 형태가 올바른지 확인 (middleUnitId=1111&middleUnitId=1112&...)
        #expect(urlString.contains("middleUnitId=1111"))
        #expect(urlString.contains("middleUnitId=1112"))
        #expect(urlString.contains("middleUnitId=1121"))
        #expect(urlString.contains("middleUnitId=1122"))
        #expect(urlString.contains("middleUnitId=1131"))
        #expect(urlString.contains("middleUnitId=1132"))
        #expect(urlString.contains("middleUnitId=1141"))
        #expect(urlString.contains("middleUnitId=1142"))

        // middleUnitId가 JSON 배열 형태가 아니어야 함
        #expect(!urlString.contains("middleUnitId=%5B"))

        // middleUnitId가 개별 파라미터로 분리되어 있는지 확인
        let middleUnitIdPattern = "middleUnitId=1111&middleUnitId=1112"
        #expect(urlString.contains(middleUnitIdPattern))

        print("✅ Generated URL: \(urlString)")
    }
}
