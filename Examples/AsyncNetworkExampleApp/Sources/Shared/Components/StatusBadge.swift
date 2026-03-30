//
//  StatusBadge.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import SwiftUI

enum StatusBadgeStyle: Equatable {
    case idle
    case loading
    case success
    case failure
    case live

    var color: Color {
        switch self {
        case .idle: return .secondary
        case .loading: return .orange
        case .success: return .green
        case .failure: return .red
        case .live: return .blue
        }
    }
}

struct StatusBadge: View {
    let text: String
    let style: StatusBadgeStyle

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(style.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(style.color.opacity(0.12))
            .clipShape(Capsule())
    }
}
