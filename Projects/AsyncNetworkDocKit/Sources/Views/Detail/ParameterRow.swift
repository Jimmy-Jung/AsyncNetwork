//
//  ParameterRow.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkCore

/// 파라미터 행
@available(iOS 17.0, macOS 14.0, *)
struct ParameterRow: View {
    let parameter: ParameterInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(parameter.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                
                Text(parameter.location.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                if parameter.isRequired {
                    Text("required")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(parameter.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let desc = parameter.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let example = parameter.exampleValue {
                Text("Example: \(example)")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

