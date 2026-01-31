//
//  UserDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import Foundation

@ResponseTestable(defaultArrayCount: 10)
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

@ResponseTestable
struct AddressDTO: Codable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: GeoDTO
}

@ResponseTestable
struct GeoDTO: Codable, Sendable {
    let lat: String
    let lng: String
}

@ResponseTestable
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
