//
//  APIPlaygroundViewController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import SwiftUI
import UIKit

/// SwiftUI API Playground를 호스팅하는 UIKit ViewController
final class APIPlaygroundViewController<Service: NetworkMonitoringService>: UIHostingController<APIPlaygroundView<Service>> {
    init(networkService: NetworkService, networkMonitoring: Service) {
        super.init(rootView: APIPlaygroundView(
            networkService: networkService,
            networkMonitoring: networkMonitoring
        ))
        title = "API Playground"
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
