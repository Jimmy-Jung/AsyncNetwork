//
//  GitHubRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/12.
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("GitHub API Requests Tests")
struct GitHubRequestsTests {
    // MARK: - GetGitHubUserRequest Tests

    @Test("GetGitHubUserRequest가 동적 경로를 생성하는지 확인")
    func getGitHubUserRequestPath() {
        // Given
        let request = GetGitHubUserRequest(username: "octocat")

        // When
        let path = request.path

        // Then
        #expect(path == "/users/octocat")
    }

    @Test("GetGitHubUserRequest가 username을 올바르게 설정하는지 확인")
    func getGitHubUserRequestUsername() {
        // Given
        let username = "jimmy"
        let request = GetGitHubUserRequest(username: username)

        // Then
        #expect(request.username == username)
        #expect(request.method == .get)
    }

    @Test("GetGitHubUserRequest - Success 시나리오")
    func getGitHubUserRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetGitHubUserRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil, "에러가 없어야 함")

        let httpResponse = try #require(response as? HTTPURLResponse, "HTTPURLResponse여야 함")
        #expect(httpResponse.statusCode == 200, "상태 코드가 200이어야 함")

        let responseData = try #require(data, "응답 데이터가 있어야 함")
        let githubUser = try JSONDecoder().decode(GitHubUserDTO.self, from: responseData)
        #expect(githubUser.id > 0, "GitHub 사용자는 유효한 ID를 가져야 함")
        #expect(githubUser.login.isEmpty == false, "로그인 이름이 있어야 함")
    }

    @Test("GetGitHubUserRequest - NotFound 시나리오")
    func getGitHubUserRequestNotFoundScenario() throws {
        // Given
        let (data, response, error) = GetGitHubUserRequest.mockResponse(for: .notFound)

        // Then
        #expect(error == nil, "네트워크 에러는 없어야 함")

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404, "상태 코드가 404여야 함")

        let errorData = try #require(data, "에러 데이터가 있어야 함")

        // GitHub API 에러 응답 형식 검증
        let errorResponse = try JSONDecoder().decode([String: String].self, from: errorData)
        #expect(errorResponse["message"] != nil, "에러 메시지가 있어야 함")
    }

    @Test("GetGitHubUserRequest - ServerError 시나리오")
    func getGitHubUserRequestServerErrorScenario() throws {
        // Given
        let (data, response, error) = GetGitHubUserRequest.mockResponse(for: .serverError)

        // Then
        #expect(error == nil, "네트워크 에러는 없어야 함")

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 500, "상태 코드가 500이어야 함")

        // 서버 에러 응답 데이터 검증
        let errorData = try #require(data, "에러 데이터가 있어야 함")
        let errorResponse = try JSONDecoder().decode([String: String].self, from: errorData)
        #expect(errorResponse["error"] == "Internal Server Error", "에러 메시지 확인")
    }

    @Test("GetGitHubUserRequest - 다양한 사용자 이름 처리")
    func getGitHubUserRequestVariousUsernames() {
        // Given
        let usernames = ["octocat", "jimmy-jung", "user_123", "a"]

        // When/Then
        for username in usernames {
            let request = GetGitHubUserRequest(username: username)
            #expect(request.path == "/users/\(username)", "경로가 올바르게 생성되어야 함")
            #expect(request.username == username, "사용자 이름이 올바르게 설정되어야 함")
        }
    }

    @Test("GetGitHubUserRequest - API baseURL 확인")
    func getGitHubUserRequestBaseURL() throws {
        // Given
        let request = GetGitHubUserRequest(username: "octocat")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        #expect(url.scheme == "https", "HTTPS 프로토콜을 사용해야 함")
        #expect(url.host == "api.github.com", "GitHub API 호스트여야 함")
    }
}
