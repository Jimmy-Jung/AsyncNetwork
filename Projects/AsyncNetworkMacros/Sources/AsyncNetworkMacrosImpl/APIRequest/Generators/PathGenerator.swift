import SwiftSyntax

public struct PathGenerator {
    private let args: MacroArguments
    private let pathParser: PathParser
    private let properties: [PropertyInfo]

    public init(
        args: MacroArguments,
        pathParser: PathParser,
        properties: [PropertyInfo]
    ) {
        self.args = args
        self.pathParser = pathParser
        self.properties = properties
    }

    public func generate() -> [DeclSyntax] {
        let placeholders = pathParser.extractPlaceholders(from: args.path)
        return [generatePath(with: placeholders)]
    }
}

extension PathGenerator {
    private func generatePath(with placeholders: [String]) -> DeclSyntax {
        placeholders.isEmpty
            ? generateStaticPath()
            : generateDynamicPath(placeholders: placeholders)
    }

    private func generateStaticPath() -> DeclSyntax {
        let normalizedPath = pathParser.normalize(args.path)
        return createPathProperty(with: normalizedPath)
    }

    private func generateDynamicPath(placeholders: [String]) -> DeclSyntax {
        let pathWithInterpolations = convertPlaceholdersToInterpolations(placeholders)
        return createPathProperty(with: pathWithInterpolations)
    }

    private func convertPlaceholdersToInterpolations(_ placeholders: [String]) -> String {
        let normalizedPath = pathParser.normalize(args.path)
        return placeholders.reduce(normalizedPath) { path, placeholder in
            path.replacingOccurrences(
                of: "{\(placeholder)}",
                with: "\\(\(placeholder))"
            )
        }
    }

    private func createPathProperty(with pathValue: String) -> DeclSyntax {
        """
        public var path: String {
            "\(raw: pathValue)"
        }
        """
    }
}
