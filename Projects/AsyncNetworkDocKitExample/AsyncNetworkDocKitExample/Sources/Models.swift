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

// MARK: - Complex Order Models

struct Order: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    let orderNumber: String
    let status: String
    let totalAmount: Double
    let items: [OrderItem]
    let shippingAddress: ShippingAddress
    let paymentMethod: PaymentMethod
    let createdAt: String
    let estimatedDelivery: String?
}

struct OrderItem: Codable, Sendable {
    let productId: Int
    let productName: String
    let quantity: Int
    let unitPrice: Double
    let discount: Double?
    let options: [String: String]?
}

struct ShippingAddress: Codable, Sendable {
    let recipientName: String
    let phoneNumber: String
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let instructions: String?
}

struct PaymentMethod: Codable, Sendable {
    let type: String
    let cardLastFour: String?
    let cardBrand: String?
}

struct CreateOrderBody: Codable, Sendable {
    let items: [OrderItemInput]
    let shippingAddress: ShippingAddress
    let paymentMethod: PaymentMethodInput
    let couponCode: String?
    let giftMessage: String?
    let subscribeNewsletter: Bool
}

struct OrderItemInput: Codable, Sendable {
    let productId: Int
    let quantity: Int
    let options: [String: String]?
}

struct PaymentMethodInput: Codable, Sendable {
    let type: String
    let cardToken: String?
    let bankAccountId: String?
}

// MARK: - Complex Profile Models

struct UserProfile: Codable, Identifiable, Sendable {
    let id: Int
    let username: String
    let email: String
    let fullName: String
    let avatar: String?
    let bio: String?
    let preferences: UserPreferences
    let socialLinks: SocialLinks?
    let stats: UserStats
    let badges: [Badge]
    let isPremium: Bool
    let memberSince: String
}

struct UserPreferences: Codable, Sendable {
    let language: String
    let timezone: String
    let theme: String
    let notifications: NotificationSettings
    let privacy: PrivacySettings
}

struct NotificationSettings: Codable, Sendable {
    let email: Bool
    let push: Bool
    let sms: Bool
    let frequency: String
}

struct PrivacySettings: Codable, Sendable {
    let profileVisibility: String
    let showEmail: Bool
    let showActivity: Bool
}

struct SocialLinks: Codable, Sendable {
    let twitter: String?
    let github: String?
    let linkedin: String?
    let website: String?
}

struct UserStats: Codable, Sendable {
    let posts: Int
    let followers: Int
    let following: Int
    let likes: Int
}

struct Badge: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let icon: String
    let description: String
    let earnedAt: String
}

struct UpdateProfileBody: Codable, Sendable {
    let fullName: String
    let bio: String?
    let avatar: String?
    let preferences: UserPreferences
    let socialLinks: SocialLinks?
}

// MARK: - Search Filter Models

struct SearchResult: Codable, Sendable {
    let items: [SearchItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let facets: [Facet]
}

struct SearchItem: Codable, Identifiable, Sendable {
    let id: Int
    let type: String
    let title: String
    let description: String
    let thumbnail: String?
    let author: Author
    let tags: [String]
    let createdAt: String
    let score: Double
}

struct Author: Codable, Sendable {
    let id: Int
    let name: String
    let avatar: String?
}

struct Facet: Codable, Sendable {
    let name: String
    let values: [FacetValue]
}

struct FacetValue: Codable, Sendable {
    let value: String
    let count: Int
}

struct SearchFilterBody: Codable, Sendable {
    let query: String
    let filters: SearchFilters
    let sort: SortOptions
    let pagination: PaginationOptions
}

struct SearchFilters: Codable, Sendable {
    let categories: [String]?
    let tags: [String]?
    let authors: [Int]?
    let dateRange: DateRange?
    let priceRange: PriceRange?
    let rating: Int?
    let inStock: Bool?
}

struct DateRange: Codable, Sendable {
    let from: String
    let to: String
}

struct PriceRange: Codable, Sendable {
    let min: Double
    let max: Double
}

struct SortOptions: Codable, Sendable {
    let field: String
    let order: String
}

struct PaginationOptions: Codable, Sendable {
    let page: Int
    let pageSize: Int
}
