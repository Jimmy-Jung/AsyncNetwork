//
//  PostRepositoryImplTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncNetwork

@Suite("PostRepositoryImpl Tests")
struct PostRepositoryImplTests {
    
    @Test("getAllPosts가 NetworkService를 통해 Post 목록을 반환하는지 확인")
    func testGetAllPosts() async throws {
        // Given
        let mockService = createMockNetworkService()
        let repository = PostRepositoryImpl(networkService: mockService)
        
        // When
        let posts = try await repository.getAllPosts()
        
        // Then
        #expect(!posts.isEmpty)
        #expect(posts.count == 2)
        #expect(posts[0].title.contains("Mock"))
    }
    
    @Test("getPost가 특정 Post를 반환하는지 확인")
    func testGetPostById() async throws {
        // Given
        let mockService = createMockNetworkService()
        let repository = PostRepositoryImpl(networkService: mockService)
        
        // When
        let post = try await repository.getPost(by: 1)
        
        // Then
        #expect(post.id == 1)
        #expect(!post.title.isEmpty)
    }
    
    @Test("createPost가 새 Post를 생성하는지 확인")
    func testCreatePost() async throws {
        // Given
        let mockService = createMockNetworkService()
        let repository = PostRepositoryImpl(networkService: mockService)
        
        // @Response 매크로의 builder() 사용
        let newPost = Post(
            dto: PostDTO.builder()
                .with(id: 0)
                .with(userId: 1)
                .with(title: "New Post")
                .with(body: "New Body")
                .build()
        )
        
        // When
        let createdPost = try await repository.createPost(newPost)
        
        // Then
        // Mock은 fixture()를 반환하므로 fixture 값과 비교
        #expect(createdPost.title == PostDTO.fixture().title)
        #expect(createdPost.body == PostDTO.fixture().body)
    }
    
    @Test("updatePost가 Post를 업데이트하는지 확인")
    func testUpdatePost() async throws {
        // Given
        let mockService = createMockNetworkService()
        let repository = PostRepositoryImpl(networkService: mockService)
        
        // @Response 매크로의 fixture() 사용
        let updatedPost = Post(dto: PostDTO.fixture())
        
        // When
        let result = try await repository.updatePost(updatedPost)
        
        // Then
        #expect(result.id == updatedPost.id)
    }
    
    @Test("PostDTO mock 데이터가 도메인 모델로 변환되는지 확인")
    func testPostDTOMockConversion() throws {
        // Given - @Response 매크로의 mock() 사용
        let dto = PostDTO.mock()
        
        // When
        let domainModel = Post(dto: dto)
        
        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.userId == dto.userId)
        #expect(domainModel.title == dto.title)
        #expect(domainModel.body == dto.body)
        
        // assertValid() 검증
        try dto.assertValid()
    }
    
    @Test("PostDTO fixture가 일관된 데이터를 제공하는지 확인")
    func testPostDTOFixtureConsistency() {
        // Given - @Response 매크로의 fixture() 사용
        let fixture1 = PostDTO.fixture()
        let fixture2 = PostDTO.fixture()
        
        // When
        let domain1 = Post(dto: fixture1)
        let domain2 = Post(dto: fixture2)
        
        // Then - Fixture는 항상 동일
        #expect(domain1.id == domain2.id)
        #expect(domain1.title == domain2.title)
    }
    
    @Test("PostDTO builder로 테스트 데이터 생성이 가능한지 확인")
    func testPostDTOBuilder() throws {
        // Given - @Response 매크로의 builder() 사용
        let customDTO = PostDTO.builder()
            .with(id: 999)
            .with(userId: 42)
            .with(title: "Custom Title")
            .with(body: "Custom Body")
            .build()
        
        // When
        let domain = Post(dto: customDTO)
        
        // Then
        #expect(domain.id == 999)
        #expect(domain.userId == 42)
        #expect(domain.title == "Custom Title")
        
        try customDTO.assertValid()
    }
    
    @Test("PostDTO mockArray로 여러 테스트 데이터를 생성하는지 확인")
    func testPostDTOMockArray() throws {
        // Given - @Response 매크로의 mockArray() 사용
        let dtos = PostDTO.mockArray(count: 5)
        
        // When
        let domains = dtos.map(Post.init)
        
        // Then
        #expect(domains.count == 5)
        
        // 모든 Mock이 유효한지 확인
        for dto in dtos {
            try dto.assertValid()
        }
    }
}

// MARK: - Mock HTTPClient

/// NetworkService의 HTTPClient를 Mock으로 교체하여 테스트합니다.
private actor MockHTTPClient: HTTPClientProtocol {
    func request(_ request: any APIRequest) async throws -> HTTPResponse {
        // URLRequest로 변환하여 처리
        let urlRequest = try request.asURLRequest()
        return try await self.request(urlRequest)
    }
    
    func request(_ request: URLRequest) async throws -> HTTPResponse {
        // URL path를 기반으로 적절한 응답 반환
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        
        // 상태 코드 설정
        let statusCode = 200
        
        // 응답 데이터 생성
        let data: Data
        
        if path.contains("/posts") && !path.contains("/comments") {
            // GET /posts/{id} - 단일 Post 조회
            if method == "GET" && path.components(separatedBy: "/").count > 2 {
                let dto = PostDTO.fixture()
                data = try JSONEncoder().encode(dto)
            }
            // GET /posts - 전체 Posts 조회
            else if method == "GET" {
                let dtos = PostDTO.mockArray(count: 2)
                data = try JSONEncoder().encode(dtos)
            }
            // POST /posts - Post 생성 (단일 객체 반환)
            else if method == "POST" {
                let dto = PostDTO.fixture()
                data = try JSONEncoder().encode(dto)
            }
            // PUT /posts/{id} - Post 업데이트 (단일 객체 반환)
            else if method == "PUT" {
                let dto = PostDTO.fixture()
                data = try JSONEncoder().encode(dto)
            }
            // DELETE - EmptyResponse
            else {
                data = Data("{}".utf8)
            }
        } else {
            // EmptyResponse (기타)
            data = Data("{}".utf8)
        }
        
        // HTTPURLResponse 생성
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        return HTTPResponse(
            statusCode: statusCode,
            data: data,
            request: request,
            response: httpResponse
        )
    }
}

/// Mock NetworkService 생성 헬퍼
private func createMockNetworkService() -> NetworkService {
    NetworkService(
        httpClient: MockHTTPClient(),
        retryPolicy: RetryPolicy(),
        responseProcessor: ResponseProcessor(),
        interceptors: []
    )
}

