//
//  AsyncNetworkDocKitExampleApp.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkDocKit
import Foundation
import SwiftUI

@main
@available(iOS 17.0, *)
struct AsyncNetworkDocKitExampleApp: App {
    let networkService = NetworkService()

    init() {
        // 모든 @DocumentedType 타입을 자동으로 등록
        // GenerateTypeRegistration.swift 스크립트가 빌드 시 자동 생성합니다
        registerAllTypesGenerated()
    }

    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: Self.endpointsGenerated,
            networkService: networkService,
            appTitle: "AsyncNetwork API Documentation"
        )
    }
}
