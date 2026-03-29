//
//  DemoRunOutput.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import Foundation

struct DemoRunOutput: Equatable, Sendable {
    let method: String
    let requestURL: String
    let headers: [String]
    let metadataLines: [String]
    let responsePreview: String
}

enum DemoLoadState: Equatable, Sendable {
    case idle
    case loading
    case success(DemoRunOutput)
    case failure(String)
}
