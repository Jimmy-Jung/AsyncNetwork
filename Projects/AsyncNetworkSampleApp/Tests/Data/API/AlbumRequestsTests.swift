//
//  AlbumRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncNetwork

@Suite("Album & Photo API Requests Tests")
struct AlbumRequestsTests {
    
    // MARK: - GetAlbumsForUserRequest Tests
    
    @Test("GetAlbumsForUserRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func testGetAlbumsForUserRequestQueryParameters() {
        // Given
        var request = GetAlbumsForUserRequest()
        request.userId = 3
        request.limit = 10
        
        // Then
        #expect(request.userId == 3)
        #expect(request.limit == 10)
    }
    
    // MARK: - GetAlbumByIdRequest Tests
    
    @Test("GetAlbumByIdRequest가 동적 경로를 생성하는지 확인")
    func testGetAlbumByIdRequestPath() throws {
        // Given
        var request = GetAlbumByIdRequest(id: 15)
        
        // When
        let urlRequest = try request.asURLRequest()
        
        // Then
        let url = try #require(urlRequest.url)
        #expect(url.path == "/albums/15")
    }
    
    // MARK: - GetPhotosForAlbumRequest Tests
    
    @Test("GetPhotosForAlbumRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func testGetPhotosForAlbumRequestQueryParameters() {
        // Given
        var request = GetPhotosForAlbumRequest()
        request.albumId = 7
        request.limit = 50
        
        // Then
        #expect(request.albumId == 7)
        #expect(request.limit == 50)
    }
    
    // MARK: - GetPhotoByIdRequest Tests
    
    @Test("GetPhotoByIdRequest가 동적 경로를 생성하는지 확인")
    func testGetPhotoByIdRequestPath() throws {
        // Given
        var request = GetPhotoByIdRequest(id: 99)
        
        // When
        let urlRequest = try request.asURLRequest()
        
        // Then
        let url = try #require(urlRequest.url)
        #expect(url.path == "/photos/99")
    }
    
    // MARK: - Error Response Models Tests
    
    @Test("AlbumNotFoundError가 Codable을 준수하는지 확인")
    func testAlbumNotFoundErrorCodable() throws {
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
    func testPhotoNotFoundErrorCodable() throws {
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
