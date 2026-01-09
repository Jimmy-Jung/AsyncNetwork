//
//  UserDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import Foundation

@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "id": 1,
      "name": "Leanne Graham",
      "username": "Bret",
      "email": "Sincere@april.biz",
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
      "phone": "1-770-736-8031 x56442",
      "website": "hildegard.org",
      "company": {
        "name": "Romaguera-Crona",
        "catchPhrase": "Multi-layered client-server neural-net",
        "bs": "harness real-time e-markets"
      }
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 10
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: AddressDTO?
    let phone: String?
    let website: String?
    let company: CompanyDTO?
}

@Response(
    mockStrategy: .random,
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
    """,
    includeBuilder: true,
    defaultArrayCount: 5
)
struct AddressDTO: Codable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: GeoDTO
}

@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "lat": "-37.3159",
      "lng": "81.1496"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 5
)
struct GeoDTO: Codable, Sendable {
    let lat: String
    let lng: String
}

@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "name": "Romaguera-Crona",
      "catchPhrase": "Multi-layered client-server neural-net",
      "bs": "harness real-time e-markets"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 5
)
struct CompanyDTO: Codable, Sendable {
    let name: String
    let catchPhrase: String
    let bs: String
}

// MARK: - Domain Model Conversion

extension User {
    init(dto: UserDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            username: dto.username,
            email: dto.email,
            address: dto.address.map(Address.init),
            phone: dto.phone,
            website: dto.website,
            company: dto.company.map(Company.init)
        )
    }
}

extension Address {
    init(dto: AddressDTO) {
        self.init(
            street: dto.street,
            suite: dto.suite,
            city: dto.city,
            zipcode: dto.zipcode,
            geo: Geo(dto: dto.geo)
        )
    }
}

extension Geo {
    init(dto: GeoDTO) {
        self.init(
            lat: dto.lat,
            lng: dto.lng
        )
    }
}

extension Company {
    init(dto: CompanyDTO) {
        self.init(
            name: dto.name,
            catchPhrase: dto.catchPhrase,
            bs: dto.bs
        )
    }
}

