//
//  AlbumRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Added @APITestable MockScenario tests
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("Album & Photo API Requests Tests")
struct AlbumRequestsTests {
    // MARK: - GetAlbumsForUserRequest Tests

    @Test("GetAlbumsForUserRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func getAlbumsForUserRequestQueryParameters() {
        // Given
        let request = GetAlbumsForUserRequest(userId: 3, limit: 10)

        // Then
        #expect(request.userId == 3)
        #expect(request.limit == 10)
    }

    @Test("GetAlbumsForUserRequest - Success 시나리오")
    func getAlbumsForUserRequestSuccessScenario() throws {
        // Given: @APITestable이 생성한 MockScenario.success
        let (data, response, error) = GetAlbumsForUserRequest.mockResponse(for: .success)

        // Then: 성공 응답 검증
        #expect(error == nil, "에러가 없어야 함")

        let httpResponse = try #require(response as? HTTPURLResponse, "HTTPURLResponse여야 함")
        #expect(httpResponse.statusCode == 200, "상태 코드가 200이어야 함")

        let responseData = try #require(data, "응답 데이터가 있어야 함")
        let albums = try JSONDecoder().decode([AlbumDTO].self, from: responseData)
        #expect(!albums.isEmpty, "앨범 배열이 비어있지 않아야 함")
    }

    @Test("GetAlbumsForUserRequest - ClientError 시나리오")
    func getAlbumsForUserRequestClientErrorScenario() throws {
        // Given: @APITestable이 생성한 MockScenario.clientError
        let (data, response, error) = GetAlbumsForUserRequest.mockResponse(for: .clientError)

        // Then: 400 에러 응답 검증
        #expect(error == nil, "네트워크 에러는 없어야 함")

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400, "상태 코드가 400이어야 함")

        let errorData = try #require(data, "에러 데이터가 있어야 함")
        let errorResponse = try JSONDecoder().decode([String: String].self, from: errorData)
        #expect(errorResponse["error"] != nil, "에러 메시지가 있어야 함")
    }

    @Test("GetAlbumsForUserRequest - ServerError 시나리오")
    func getAlbumsForUserRequestServerErrorScenario() throws {
        // Given
        let (data, response, error) = GetAlbumsForUserRequest.mockResponse(for: .serverError)

        // Then: 500 에러 응답 검증
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 500, "상태 코드가 500이어야 함")

        let errorData = try #require(data)
        let errorResponse = try JSONDecoder().decode([String: String].self, from: errorData)
        #expect(errorResponse["error"] == "Internal Server Error")
    }

    @Test("GetAlbumsForUserRequest - Timeout 시나리오")
    func getAlbumsForUserRequestTimeoutScenario() {
        // Given
        let (data, response, error) = GetAlbumsForUserRequest.mockResponse(for: .timeout)

        // Then: 타임아웃 에러 검증
        #expect(data == nil, "타임아웃 시 데이터가 없어야 함")
        #expect(response == nil, "타임아웃 시 응답이 없어야 함")
        #expect(error != nil, "타임아웃 에러가 있어야 함")

        let nsError = error as? NSError
        #expect(nsError?.code == NSURLErrorTimedOut, "타임아웃 에러 코드여야 함")
    }

    // MARK: - GetAlbumByIdRequest Tests

    @Test("GetAlbumByIdRequest가 동적 경로를 생성하는지 확인")
    func getAlbumByIdRequestPath() throws {
        // Given
        let request = GetAlbumByIdRequest(id: 15)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        #expect(url.path == "/albums/15")
    }

    @Test("GetAlbumByIdRequest - Success 시나리오")
    func getAlbumByIdRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetAlbumByIdRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let album = try JSONDecoder().decode(AlbumDTO.self, from: responseData)
        #expect(album.id > 0, "앨범 ID가 유효해야 함")
    }

    @Test("GetAlbumByIdRequest - NotFound 시나리오")
    func getAlbumByIdRequestNotFoundScenario() throws {
        // Given
        let (data, response, error) = GetAlbumByIdRequest.mockResponse(for: .notFound)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404, "상태 코드가 404여야 함")

        let errorData = try #require(data)
        let albumError = try JSONDecoder().decode(AlbumNotFoundError.self, from: errorData)
        #expect(albumError.code == "ALBUM_NOT_FOUND")
    }

    // MARK: - GetPhotosForAlbumRequest Tests

    @Test("GetPhotosForAlbumRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func getPhotosForAlbumRequestQueryParameters() {
        // Given
        let request = GetPhotosForAlbumRequest(albumId: 7, limit: 50)

        // Then
        #expect(request.albumId == 7)
        #expect(request.limit == 50)
    }

    @Test("GetPhotosForAlbumRequest - Success 시나리오")
    func getPhotosForAlbumRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetPhotosForAlbumRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let photos = try JSONDecoder().decode([PhotoDTO].self, from: responseData)
        #expect(!photos.isEmpty, "사진 배열이 비어있지 않아야 함")

        // 첫 번째 사진의 URL 검증
        if let firstPhoto = photos.first {
            #expect(firstPhoto.url.isEmpty == false, "사진 URL이 있어야 함")
            #expect(firstPhoto.thumbnailUrl.isEmpty == false, "썸네일 URL이 있어야 함")
        }
    }

    @Test("GetPhotosForAlbumRequest - ClientError 시나리오")
    func getPhotosForAlbumRequestClientErrorScenario() throws {
        // Given
        let (data, response, error) = GetPhotosForAlbumRequest.mockResponse(for: .clientError)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400)

        let errorData = try #require(data)
        let errorResponse = try JSONDecoder().decode([String: String].self, from: errorData)
        #expect(errorResponse["message"]?.contains("albumId") == true, "albumId 관련 에러 메시지여야 함")
    }

    // MARK: - GetPhotoByIdRequest Tests

    @Test("GetPhotoByIdRequest가 동적 경로를 생성하는지 확인")
    func getPhotoByIdRequestPath() throws {
        // Given
        let request = GetPhotoByIdRequest(id: 99)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        #expect(url.path == "/photos/99")
    }

    @Test("GetPhotoByIdRequest - Success 시나리오")
    func getPhotoByIdRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetPhotoByIdRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let photo = try JSONDecoder().decode(PhotoDTO.self, from: responseData)
        #expect(photo.id > 0)
        #expect(photo.albumId > 0)
    }

    @Test("GetPhotoByIdRequest - NotFound 시나리오")
    func getPhotoByIdRequestNotFoundScenario() throws {
        // Given
        let (data, response, error) = GetPhotoByIdRequest.mockResponse(for: .notFound)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)

        let errorData = try #require(data)
        let photoError = try JSONDecoder().decode(PhotoNotFoundError.self, from: errorData)
        #expect(photoError.code == "PHOTO_NOT_FOUND")
    }

    // MARK: - Error Response Models Tests

    @Test("AlbumNotFoundError가 Codable을 준수하는지 확인")
    func albumNotFoundErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Album not found",
          "code": "ALBUM_NOT_FOUND"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(AlbumNotFoundError.self, from: data)

        // Then
        #expect(error.error == "Album not found")
        #expect(error.code == "ALBUM_NOT_FOUND")
    }

    @Test("PhotoNotFoundError가 Codable을 준수하는지 확인")
    func photoNotFoundErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Photo not found",
          "code": "PHOTO_NOT_FOUND"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(PhotoNotFoundError.self, from: data)

        // Then
        #expect(error.error == "Photo not found")
        #expect(error.code == "PHOTO_NOT_FOUND")
    }
}
