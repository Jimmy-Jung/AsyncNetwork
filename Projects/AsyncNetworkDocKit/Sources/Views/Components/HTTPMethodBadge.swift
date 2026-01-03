//
//  HTTPMethodBadge.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
public struct HTTPMethodBadge: View {
    let method: String

    public init(method: String) {
        self.method = method
    }

    public var body: some View {
        Text(method.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(methodColor)
            .cornerRadius(4)
            .frame(width: 60)
    }

    private var methodColor: Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "PATCH": return .orange
        case "DELETE": return .red
        case "HEAD": return .purple
        case "OPTIONS": return .gray
        default: return .gray
        }
    }
}
