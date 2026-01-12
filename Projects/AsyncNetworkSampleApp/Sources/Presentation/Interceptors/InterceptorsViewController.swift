//
//  InterceptorsViewController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/12.
//

import SwiftUI
import UIKit

/// Request Interceptors 화면을 호스팅하는 UIKit ViewController
final class InterceptorsViewController: UIHostingController<InterceptorsView> {
    private let viewModel: InterceptorsViewModel

    init(viewModel: InterceptorsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: InterceptorsView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
