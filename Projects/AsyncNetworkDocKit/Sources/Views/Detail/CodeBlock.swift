//
//  CodeBlock.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
struct CodeBlock: View {
    let content: String

    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(maxHeight: 200)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}
