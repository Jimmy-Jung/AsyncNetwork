import SwiftSyntax

public struct MetadataGenerator: CodeGenerator {
    private let typeName: String
    private let args: MacroArguments
    private let properties: [PropertyInfo]

    public init(
        typeName: String,
        args: MacroArguments,
        properties: [PropertyInfo]
    ) {
        self.typeName = typeName
        self.args = args
        self.properties = properties
    }

    public func generate() -> [DeclSyntax] {
        [createMetadataProperty()]
    }
}

extension MetadataGenerator {
    private func createMetadataProperty() -> DeclSyntax {
        let metadata = buildMetadataComponents()

        return """
        public static var metadata: EndpointMetadata {
            EndpointMetadata(
                id: "\(raw: typeName)",
                title: "\(raw: metadata.title)",
                description: "\(raw: metadata.description)",
                method: "\(raw: metadata.method)",
                path: "\(raw: args.path)",
                baseURLString: \(raw: args.baseURL),
                headers: \(raw: metadata.headers),
                tags: [\(raw: metadata.tags)],
                parameters: \(raw: metadata.parameters),
                responseTypeName: "\(raw: args.responseType)"
            )
        }
        """
    }

    private func buildMetadataComponents() -> MetadataComponents {
        MetadataComponents(
            title: StringEscaper.escape(args.title),
            description: StringEscaper.escape(args.description),
            method: args.method.uppercased(),
            headers: buildHeadersDictionary(),
            tags: buildTagsArray(),
            parameters: buildParametersArray()
        )
    }
}

extension MetadataGenerator {
    private func buildHeadersDictionary() -> String {
        let headerProperties = properties.filter { $0.isHeader }

        guard !headerProperties.isEmpty else {
            return "[:]"
        }

        let entries = headerProperties.compactMap(formatHeaderEntry)

        // entries가 비어있으면 빈 딕셔너리 반환
        guard !entries.isEmpty else {
            return "[:]"
        }

        return "[\(entries.joined(separator: ", "))]"
    }

    private func formatHeaderEntry(_ property: PropertyInfo) -> String? {
        guard let headerKey = property.headerKey,
              let defaultValue = property.defaultValue
        else {
            return nil
        }

        let escapedValue = StringEscaper.escape(defaultValue)
        return #""\#(headerKey)": "\#(escapedValue)""#
    }

    private func buildTagsArray() -> String {
        args.tags
            .map { #""\#($0)""# }
            .joined(separator: ", ")
    }

    private func buildParametersArray() -> String {
        let parameterProperties = properties.filter { property in
            ["PathParameter", "QueryParameter"].contains(property.wrapperType)
        }

        guard !parameterProperties.isEmpty else {
            return "[]"
        }

        let parameterNames = parameterProperties.map { #""\#($0.name)""# }
        return "[\(parameterNames.joined(separator: ", "))]"
    }
}

private struct MetadataComponents {
    let title: String
    let description: String
    let method: String
    let headers: String
    let tags: String
    let parameters: String
}

private enum StringEscaper {
    static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
