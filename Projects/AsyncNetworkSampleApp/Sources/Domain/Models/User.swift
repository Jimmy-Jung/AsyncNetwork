//
//  User.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 사용자 도메인 모델
struct User: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: Address?
    let phone: String?
    let website: String?
    let company: Company?
}

/// 주소 도메인 모델
struct Address: Sendable, Equatable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo
}

/// 지리적 좌표 도메인 모델
struct Geo: Sendable, Equatable {
    let lat: String
    let lng: String
}

/// 회사 도메인 모델
struct Company: Sendable, Equatable {
    let name: String
    let catchPhrase: String
    let bs: String
}

