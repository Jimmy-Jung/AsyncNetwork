//
//  UserTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Testing
@testable import AsyncNetworkSampleApp

@Suite("User Domain Model Tests")
struct UserTests {
    @Test("User 모델이 올바르게 생성되는지 확인")
    func testUserCreation() {
        // Given
        let id = 1
        let name = "John Doe"
        let username = "johndoe"
        let email = "john@example.com"
        
        // When
        let user = User(
            id: id,
            name: name,
            username: username,
            email: email,
            address: nil,
            phone: nil,
            website: nil,
            company: nil
        )
        
        // Then
        #expect(user.id == id)
        #expect(user.name == name)
        #expect(user.username == username)
        #expect(user.email == email)
    }
    
    @Test("User가 옵셔널 필드를 처리하는지 확인")
    func testUserOptionalFields() {
        // Given
        let address = Address(
            street: "123 Main St",
            suite: "Apt 4",
            city: "New York",
            zipcode: "10001",
            geo: Geo(lat: "40.7128", lng: "-74.0060")
        )
        
        // When
        let user = User(
            id: 1,
            name: "John",
            username: "john",
            email: "john@example.com",
            address: address,
            phone: "123-456-7890",
            website: "john.com",
            company: nil
        )
        
        // Then
        #expect(user.address != nil)
        #expect(user.phone != nil)
        #expect(user.website != nil)
        #expect(user.company == nil)
    }
}

