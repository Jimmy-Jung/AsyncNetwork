//
//  UserRepository.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 사용자 데이터 접근을 위한 Repository 프로토콜
protocol UserRepository: Sendable {
    /// 모든 사용자 목록을 조회합니다.
    func getAllUsers() async throws -> [User]
    
    /// 특정 ID의 사용자를 조회합니다.
    /// - Parameter id: 사용자 ID
    func getUser(by id: Int) async throws -> User
    
    /// 새로운 사용자를 생성합니다.
    /// - Parameter user: 생성할 사용자
    /// - Returns: 생성된 사용자
    func createUser(_ user: User) async throws -> User
}

