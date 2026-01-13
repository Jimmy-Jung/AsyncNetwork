//
//  GitHubRepository.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

/// GitHub API 리포지토리 인터페이스
protocol GitHubRepository: Sendable {
    /// GitHub 사용자 정보 조회
    ///
    /// ## ETag 캐싱
    /// - 첫 요청: 서버에서 데이터 가져옴 (200 OK)
    /// - 재요청: 캐시 사용 (304 Not Modified)
    ///
    /// - Parameter username: GitHub 사용자명
    /// - Returns: GitHub 사용자 정보
    /// - Throws: NetworkError
    func getUser(username: String) async throws -> GitHubUser
}
