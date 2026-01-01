//
//  Models.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

// MARK: - Post Models

struct Post: Codable, Identifiable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct PostBody: Codable, Sendable {
    let title: String
    let body: String
    let userId: Int
}

// MARK: - User Models

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: Address?
    let phone: String?
    let website: String?
    let company: Company?
}

struct Address: Codable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo
}

struct Geo: Codable, Sendable {
    let lat: String
    let lng: String
}

struct Company: Codable, Sendable {
    let name: String
    let catchPhrase: String
    let bs: String
}

struct UserBody: Codable, Sendable {
    let name: String
    let username: String
    let email: String
}

// MARK: - Comment Models

struct Comment: Codable, Identifiable, Sendable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

struct CommentBody: Codable, Sendable {
    let postId: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - Album Models

struct Album: Codable, Identifiable, Sendable {
    let userId: Int
    let id: Int
    let title: String
}

struct Photo: Codable, Identifiable, Sendable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}

