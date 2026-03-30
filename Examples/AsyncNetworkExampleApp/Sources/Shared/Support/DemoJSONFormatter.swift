//
//  DemoJSONFormatter.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import Foundation

enum DemoJSONFormatter {
    static func prettyString<T: Encodable>(from value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8)
        else {
            return String(describing: value)
        }

        return string
    }
}
