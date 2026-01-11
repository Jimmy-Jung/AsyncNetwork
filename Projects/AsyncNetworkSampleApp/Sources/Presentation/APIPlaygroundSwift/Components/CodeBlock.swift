//
//  CodeBlock.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import SwiftUI

/// 코드 블록을 표시하는 컴포넌트 (AsyncNetworkDocKit 스타일 적용)
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

#Preview {
    CodeBlock(content: """
    {
      "id": 1,
      "title": "Sample Post",
      "body": "This is a sample post"
    }
    """)
    .padding()
}
