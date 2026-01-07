//
//  Models.swift
//  OpenAPIExample
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncNetworkMacros
import Foundation

// MARK: - Post Models

@Response(
    fixtureJSON: """
    {
      "userId": 1,
      "id": 1,
      "title": "sunt aut facere",
      "body": "quia et suscipit"
    }
    """
)
struct Post: Codable, Identifiable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

@Response(
    fixtureJSON: """
    {
      "title": "My Post Title",
      "body": "This is the post content",
      "userId": 1
    }
    """
)
struct PostBody: Codable, Sendable {
    let title: String
    let body: String
    let userId: Int
}

// MARK: - User Models

@Response(
    fixtureJSON: """
    {
      "id": 1,
      "name": "Leanne Graham",
      "username": "Bret",
      "email": "leanne@example.com",
      "address": {
        "street": "Kulas Light",
        "suite": "Apt. 556",
        "city": "Gwenborough",
        "zipcode": "92998-3874",
        "geo": {
          "lat": "-37.3159",
          "lng": "81.1496"
        }
      },
      "phone": "1-770-736-8031",
      "website": "hildegard.org",
      "company": {
        "name": "Romaguera-Crona",
        "catchPhrase": "Multi-layered client-server neural-net",
        "bs": "harness real-time e-markets"
      }
    }
    """
)
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

@Response(
    fixtureJSON: """
    {
      "street": "Kulas Light",
      "suite": "Apt. 556",
      "city": "Gwenborough",
      "zipcode": "92998-3874",
      "geo": {
        "lat": "-37.3159",
        "lng": "81.1496"
      }
    }
    """
)
struct Address: Codable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo
}

@Response(
    fixtureJSON: """
    {
      "lat": "-37.3159",
      "lng": "81.1496"
    }
    """
)
struct Geo: Codable, Sendable {
    let lat: String
    let lng: String
}

@Response(
    fixtureJSON: """
    {
      "name": "Romaguera-Crona",
      "catchPhrase": "Multi-layered client-server neural-net",
      "bs": "harness real-time e-markets"
    }
    """
)
struct Company: Codable, Sendable {
    let name: String
    let catchPhrase: String
    let bs: String
}

@Response(
    fixtureJSON: """
    {
      "name": "Leanne Graham",
      "username": "Bret",
      "email": "leanne@example.com"
    }
    """
)
struct UserBody: Codable, Sendable {
    let name: String
    let username: String
    let email: String
}

// MARK: - Comment Models

@Response(
    fixtureJSON: """
    {
      "postId": 1,
      "id": 1,
      "name": "id labore ex et quam laborum",
      "email": "eliseo@example.com",
      "body": "laudantium enim quasi est quidem"
    }
    """
)
struct Comment: Codable, Identifiable, Sendable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

@Response(
    fixtureJSON: """
    {
      "postId": 1,
      "name": "My Comment",
      "email": "user@example.com",
      "body": "This is my comment"
    }
    """
)
struct CommentBody: Codable, Sendable {
    let postId: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - Album Models

@Response(
    fixtureJSON: """
    {
      "userId": 1,
      "id": 1,
      "title": "quidem molestiae enim"
    }
    """
)
struct Album: Codable, Identifiable, Sendable {
    let userId: Int
    let id: Int
    let title: String
}

@Response(
    fixtureJSON: """
    {
      "albumId": 1,
      "id": 1,
      "title": "accusamus beatae ad facilis",
      "url": "https://via.placeholder.com/600/92c952",
      "thumbnailUrl": "https://via.placeholder.com/150/92c952"
    }
    """
)
struct Photo: Codable, Identifiable, Sendable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}

// MARK: - Complex Order Models

@Response(
    fixtureJSON: """
    {
      "id": 9001,
      "userId": 42,
      "orderNumber": "ORD-2026-001234",
      "status": "pending",
      "totalAmount": 89500.50,
      "items": [
        {
          "productId": 101,
          "productName": "Premium T-Shirt",
          "quantity": 2,
          "unitPrice": 29900.00,
          "discount": 2000.00,
          "options": { "color": "blue", "size": "L" }
        }
      ],
      "shippingAddress": {
        "recipientName": "홍길동",
        "phoneNumber": "010-1234-5678",
        "street": "테헤란로 123",
        "city": "서울",
        "state": "서울특별시",
        "zipCode": "06234",
        "country": "KR",
        "instructions": "문 앞에 놔주세요"
      },
      "paymentMethod": {
        "type": "card",
        "cardLastFour": "1234",
        "cardBrand": "Visa"
      },
      "createdAt": "2026-01-02T10:30:00Z",
      "estimatedDelivery": "2026-01-05T18:00:00Z"
    }
    """
)
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

@Response(
    fixtureJSON: """
    {
      "productId": 101,
      "productName": "Premium T-Shirt",
      "quantity": 2,
      "unitPrice": 29900.00,
      "discount": 2000.00,
      "options": { "color": "blue", "size": "L" }
    }
    """
)
struct OrderItem: Codable, Sendable {
    let productId: Int
    let productName: String
    let quantity: Int
    let unitPrice: Double
    let discount: Double?
    let options: [String: String]?
}

@Response(
    fixtureJSON: """
    {
      "recipientName": "홍길동",
      "phoneNumber": "010-1234-5678",
      "street": "테헤란로 123",
      "city": "서울",
      "state": "서울특별시",
      "zipCode": "06234",
      "country": "KR",
      "instructions": "문 앞에 놔주세요"
    }
    """
)
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

@Response(
    fixtureJSON: """
    {
      "type": "card",
      "cardLastFour": "1234",
      "cardBrand": "Visa"
    }
    """
)
struct PaymentMethod: Codable, Sendable {
    let type: String
    let cardLastFour: String?
    let cardBrand: String?
}

@Response(
    fixtureJSON: """
    {
      "items": [
        {
          "productId": 101,
          "quantity": 2,
          "options": { "color": "blue", "size": "L" }
        }
      ],
      "shippingAddress": {
        "recipientName": "홍길동",
        "phoneNumber": "010-1234-5678",
        "street": "테헤란로 123",
        "city": "서울",
        "state": "서울특별시",
        "zipCode": "06234",
        "country": "KR",
        "instructions": "문 앞에 놔주세요"
      },
      "paymentMethod": {
        "type": "card",
        "cardToken": "tok_1234567890abcdef",
        "bankAccountId": null
      },
      "couponCode": "SUMMER2026",
      "giftMessage": "생일 축하해요!",
      "subscribeNewsletter": true
    }
    """
)
struct CreateOrderBody: Codable, Sendable {
    let items: [OrderItemInput]
    let shippingAddress: ShippingAddress
    let paymentMethod: PaymentMethodInput
    let couponCode: String?
    let giftMessage: String?
    let subscribeNewsletter: Bool
}

@Response(
    fixtureJSON: """
    {
      "productId": 101,
      "quantity": 2,
      "options": { "color": "blue", "size": "L" }
    }
    """
)
struct OrderItemInput: Codable, Sendable {
    let productId: Int
    let quantity: Int
    let options: [String: String]?
}

@Response(
    fixtureJSON: """
    {
      "type": "card",
      "cardToken": "tok_1234567890abcdef",
      "bankAccountId": null
    }
    """
)
struct PaymentMethodInput: Codable, Sendable {
    let type: String
    let cardToken: String?
    let bankAccountId: String?
}

// MARK: - Empty Response

struct EmptyResponse: Codable, Sendable {}
