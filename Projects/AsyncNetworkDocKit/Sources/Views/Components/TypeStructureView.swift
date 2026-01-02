//
//  TypeStructureView.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/02.
//

import SwiftUI

/// 타입 구조를 토글 가능하게 표시하는 뷰
@available(iOS 17.0, macOS 14.0, *)
struct TypeStructureView: View {
    let structureText: String
    let allTypes: [String: TypeStructure]

    @State private var expandedTypes: Set<String> = []

    init(structureText: String, allTypes: [String: TypeStructure] = [:]) {
        self.structureText = structureText
        self.allTypes = allTypes
    }

    var body: some View {
        if let mainType = TypeStructureParser.parse(structureText) {
            VStack(alignment: .leading, spacing: 0) {
                typeHeader(mainType)
                typeBody(mainType, depth: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        } else {
            // 파싱 실패 시 기존 CodeBlock 스타일로 표시
            ScrollView {
                Text(structureText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 200)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private func typeHeader(_ type: TypeStructure) -> some View {
        HStack(spacing: 4) {
            Text("struct")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.purple)
                .fontWeight(.semibold)

            Text(type.name)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .fontWeight(.bold)

            Text("{")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func typeBody(_ type: TypeStructure, depth: Int) -> some View {
        ForEach(type.properties) { property in
            propertyRow(property, depth: depth)
        }

        HStack(spacing: 4) {
            Text(String(repeating: "    ", count: depth))
                .font(.system(.caption2, design: .monospaced))
            Text("}")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func propertyRow(_ property: TypeProperty, depth: Int) -> some View {
        let indent = String(repeating: "    ", count: depth + 1)

        VStack(alignment: .leading, spacing: 4) {
            // 프로퍼티 라인
            HStack(spacing: 4) {
                Text(indent)
                    .font(.system(.caption2, design: .monospaced))

                Text("let")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.purple)

                Text(property.name)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)

                Text(":")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                if let nestedTypeName = property.nestedTypeName,
                   allTypes[nestedTypeName] != nil
                {
                    // 중첩 타입이 있는 경우 토글 버튼
                    Button {
                        toggleExpanded(nestedTypeName)
                    } label: {
                        HStack(spacing: 4) {
                            Text(property.displayType)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.blue)
                                .fontWeight(.medium)

                            Image(systemName: expandedTypes.contains(nestedTypeName) ? "chevron.down.circle.fill" : "chevron.right.circle")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    // 프리미티브 타입
                    Text(property.displayType)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                }
            }

            // 중첩 타입이 확장된 경우 표시
            if let nestedTypeName = property.nestedTypeName,
               let nestedType = allTypes[nestedTypeName],
               expandedTypes.contains(nestedTypeName)
            {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(String(repeating: "    ", count: depth + 2))
                            .font(.system(.caption2, design: .monospaced))

                        Text("// \(nestedTypeName) structure:")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.green)
                            .italic()
                    }

                    nestedTypeBody(nestedType, depth: depth + 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(4)
            }
        }
    }

    @ViewBuilder
    private func nestedTypeBody(_ type: TypeStructure, depth: Int) -> some View {
        let indent = String(repeating: "    ", count: depth)

        HStack(spacing: 4) {
            Text(indent)
                .font(.system(.caption2, design: .monospaced))
            Text("{")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }

        ForEach(type.properties) { property in
            nestedPropertyRow(property, depth: depth)
        }

        HStack(spacing: 4) {
            Text(indent)
                .font(.system(.caption2, design: .monospaced))
            Text("}")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func nestedPropertyRow(_ property: TypeProperty, depth: Int) -> some View {
        let indent = String(repeating: "    ", count: depth + 1)

        HStack(spacing: 4) {
            Text(indent)
                .font(.system(.caption2, design: .monospaced))

            Text("let")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.purple)

            Text(property.name)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .fontWeight(.medium)

            Text(":")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(property.displayType)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.blue)
        }
    }

    private func toggleExpanded(_ typeName: String) {
        if expandedTypes.contains(typeName) {
            expandedTypes.remove(typeName)
        } else {
            expandedTypes.insert(typeName)
        }
    }
}

#Preview {
    let sampleStructure = """
    struct Order {
        let id: Int
        let userId: Int
        let orderNumber: String
        let status: String
        let totalAmount: Double
        let items: [OrderItem]
        let shippingAddress: ShippingAddress
        let paymentMethod: PaymentMethod
        let createdAt: String
        let estimatedDelivery: String?
    }
    """

    let orderItemStructure = TypeStructure(
        name: "OrderItem",
        properties: [
            TypeProperty(name: "productId", type: "Int"),
            TypeProperty(name: "productName", type: "String"),
            TypeProperty(name: "quantity", type: "Int"),
            TypeProperty(name: "unitPrice", type: "Double"),
            TypeProperty(name: "discount", type: "Double", isOptional: true),
        ]
    )

    let shippingAddressStructure = TypeStructure(
        name: "ShippingAddress",
        properties: [
            TypeProperty(name: "recipientName", type: "String"),
            TypeProperty(name: "phoneNumber", type: "String"),
            TypeProperty(name: "street", type: "String"),
            TypeProperty(name: "city", type: "String"),
            TypeProperty(name: "state", type: "String"),
            TypeProperty(name: "zipCode", type: "String"),
            TypeProperty(name: "country", type: "String"),
        ]
    )

    let paymentMethodStructure = TypeStructure(
        name: "PaymentMethod",
        properties: [
            TypeProperty(name: "type", type: "String"),
            TypeProperty(name: "cardLastFour", type: "String", isOptional: true),
            TypeProperty(name: "cardBrand", type: "String", isOptional: true),
        ]
    )

    let allTypes: [String: TypeStructure] = [
        "OrderItem": orderItemStructure,
        "ShippingAddress": shippingAddressStructure,
        "PaymentMethod": paymentMethodStructure,
    ]

    return ScrollView {
        if #available(iOS 17.0, macOS 14.0, *) {
            TypeStructureView(structureText: sampleStructure, allTypes: allTypes)
                .padding()
        }
    }
}
