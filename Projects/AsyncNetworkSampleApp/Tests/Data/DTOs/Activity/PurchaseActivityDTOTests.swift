//
//  PurchaseActivityDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("PurchaseActivityDTO Tests")
struct PurchaseActivityDTOTests {
    @Test("PurchaseActivityDTO.mock()이 유효한 데이터를 생성하는지 확인")
    func purchaseActivityDTOMock() {
        let mock = PurchaseActivityDTO.mock()

        #expect(!mock.id.isEmpty)
        #expect(!mock.userId.isEmpty)
        #expect(!mock.productId.isEmpty)
        #expect(!mock.productName.isEmpty)
        #expect(mock.amount > 0)

        mock.assertValid()
    }

    @Test("PurchaseActivityDTO.builder()로 특정 구매 정보 설정")
    func purchaseActivityDTOBuilderCustom() {
        let productName = "Premium Subscription"
        let amount = 9.99
        let currency = "USD"

        let custom = PurchaseActivityDTO.builder()
            .with(id: "purchase-001")
            .with(type: ActivityType.purchase.rawValue)
            .with(userId: "user-123")
            .with(productId: "prod-premium")
            .with(productName: productName)
            .with(amount: amount)
            .with(currency: currency)
            .with(timestamp: "2026-02-01T10:00:00Z")
            .build()

        #expect(custom.productName == productName)
        #expect(custom.amount == amount)
        #expect(custom.currency == currency)

        custom.assertValid()
    }
}
