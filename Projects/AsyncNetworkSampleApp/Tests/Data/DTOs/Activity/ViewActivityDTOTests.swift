//
//  ViewActivityDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("ViewActivityDTO Tests")
struct ViewActivityDTOTests {
    @Test("ViewActivityDTO.mock()이 유효한 데이터를 생성하는지 확인")
    func viewActivityDTOMock() {
        let mock = ViewActivityDTO.mock()

        #expect(!mock.id.isEmpty)
        #expect(!mock.userId.isEmpty)
        #expect(!mock.contentId.isEmpty)
        #expect(!mock.contentType.isEmpty)
        #expect(mock.duration >= 0)

        mock.assertValid()
    }

    @Test("ViewActivityDTO.builder()로 특정 조회 정보 설정")
    func viewActivityDTOBuilderCustom() {
        let contentType = "video"
        let duration = 3600

        let custom = ViewActivityDTO.builder()
            .with(id: "view-001")
            .with(type: ActivityType.view.rawValue)
            .with(userId: "user-123")
            .with(contentId: "content-456")
            .with(contentType: contentType)
            .with(duration: duration)
            .with(timestamp: "2026-02-01T10:00:00Z")
            .build()

        #expect(custom.contentType == contentType)
        #expect(custom.duration == duration)

        custom.assertValid()
    }
}
