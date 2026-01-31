//
//  Models.swift
//  OpenAPIExample
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/14 - Migrated to @ResponseDocument
//

import AsyncNetwork
import Foundation

// MARK: - Post Models

@ResponseTestablestruct Post: Codable, Identifiable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

@ResponseTestablestruct PostBody: Codable, Sendable {
    let title: String
    let body: String
    let userId: Int
}

// MARK: - User Models

@ResponseTestablestruct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: Address?
    let phone: String?
    let website: String?
    let company: Company?
}

@ResponseTestablestruct Address: Codable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo
}

@ResponseTestablestruct Geo: Codable, Sendable {
    let lat: String
    let lng: String
}

@ResponseTestablestruct Company: Codable, Sendable {
    let name: String
    let catchPhrase: String
    let bs: String
}

@ResponseTestablestruct UserBody: Codable, Sendable {
    let name: String
    let username: String
    let email: String
}

// MARK: - Comment Models

@ResponseTestablestruct Comment: Codable, Identifiable, Sendable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

@ResponseTestablestruct CommentBody: Codable, Sendable {
    let postId: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - Album Models

@ResponseTestablestruct Album: Codable, Identifiable, Sendable {
    let userId: Int
    let id: Int
    let title: String
}

@ResponseTestablestruct Photo: Codable, Identifiable, Sendable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}

// MARK: - Complex Order Models

@ResponseTestablestruct Order: Codable, Identifiable, Sendable {
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

@ResponseTestablestruct OrderItem: Codable, Sendable {
    let productId: Int
    let productName: String
    let quantity: Int
    let unitPrice: Double
    let discount: Double?
    let options: [String: String]?
}

@ResponseTestablestruct ShippingAddress: Codable, Sendable {
    let recipientName: String
    let phoneNumber: String
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let instructions: String?
}

@ResponseTestablestruct PaymentMethod: Codable, Sendable {
    let type: String
    let cardLastFour: String?
    let cardBrand: String?
}

@ResponseTestablestruct CreateOrderBody: Codable, Sendable {
    let items: [OrderItemInput]
    let shippingAddress: ShippingAddress
    let paymentMethod: PaymentMethodInput
    let couponCode: String?
    let giftMessage: String?
    let subscribeNewsletter: Bool
}

@ResponseTestablestruct OrderItemInput: Codable, Sendable {
    let productId: Int
    let quantity: Int
    let options: [String: String]?
}

@ResponseTestablestruct PaymentMethodInput: Codable, Sendable {
    let type: String
    let cardToken: String?
    let bankAccountId: String?
}

// MARK: - Empty Response

struct EmptyResponse: Codable, Sendable {}
