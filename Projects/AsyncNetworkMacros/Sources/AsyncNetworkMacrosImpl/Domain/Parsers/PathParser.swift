public struct PathParser {
    public init() {}

    public func extractPlaceholders(from path: String) -> [String] {
        var placeholders: [String] = []
        var current = ""
        var inPlaceholder = false

        for char in path {
            if char == "{" {
                inPlaceholder = true
                current = ""
            } else if char == "}" {
                if inPlaceholder, !current.isEmpty {
                    let cleaned = current.replacingOccurrences(of: "?", with: "")

                    if isValidIdentifier(cleaned) {
                        placeholders.append(cleaned)
                    }
                }
                inPlaceholder = false
            } else if inPlaceholder {
                current.append(char)
            }
        }

        return placeholders
    }

    private func isValidIdentifier(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }

        let first = name.first!
        guard first.isLetter || first == "_" else {
            return false
        }

        for char in name.dropFirst() {
            guard char.isLetter || char.isNumber || char == "_" else {
                return false
            }
        }

        return true
    }

    public func extractOptionalParameters(from path: String) -> Set<String> {
        var optionals = Set<String>()
        var current = ""
        var inPlaceholder = false

        for char in path {
            if char == "{" {
                inPlaceholder = true
                current = ""
            } else if char == "}" {
                if inPlaceholder && current.hasSuffix("?") {
                    let name = String(current.dropLast())
                    optionals.insert(name)
                }
                inPlaceholder = false
            } else if inPlaceholder {
                current.append(char)
            }
        }

        return optionals
    }

    public func normalize(_ path: String) -> String {
        path.replacingOccurrences(of: "?}", with: "}")
    }

    public func areSimilar(_ name1: String, _ name2: String) -> Bool {
        let lower1 = name1.lowercased()
        let lower2 = name2.lowercased()

        if lower1 == lower2 {
            return true
        }

        if lower1 == lower2 + "s" || lower2 == lower1 + "s" {
            return true
        }

        let normalized1 = lower1.replacingOccurrences(of: "_", with: "")
        let normalized2 = lower2.replacingOccurrences(of: "_", with: "")
        if normalized1 == normalized2 {
            return true
        }

        return false
    }
}
