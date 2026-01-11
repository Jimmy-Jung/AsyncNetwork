//
//  HTTPMethodBadge.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import SwiftUI

/// HTTP 메서드를 표시하는 배지 컴포넌트
struct HTTPMethodBadge: View {
    let method: String

    var body: some View {
        Text(method.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(methodColor)
            .cornerRadius(4)
            .frame(minWidth: 50, idealWidth: 60, maxWidth: 60)
            .fixedSize(horizontal: true, vertical: false)
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

#Preview {
    VStack(spacing: 8) {
        HTTPMethodBadge(method: "GET")
        HTTPMethodBadge(method: "POST")
        HTTPMethodBadge(method: "PUT")
        HTTPMethodBadge(method: "DELETE")
    }
}
