import SwiftSyntax

public struct TestGenerator: CodeGenerator {
    private let args: MacroArguments
    private let responseType: String

    public init(
        args: MacroArguments,
        responseType: String
    ) {
        self.args = args
        self.responseType = responseType
    }

    public func generate() -> [DeclSyntax] {
        [
            generateMockScenarioEnum(),
            generateMockResponseMethod()
        ]
    }
}

extension TestGenerator {
    private func generateMockScenarioEnum() -> DeclSyntax {
        let cases = collectAllScenarioCases()
        let casesCode = cases.map { "case \($0)" }.joined(separator: "\n    ")

        return """
        public enum MockScenario: String, CaseIterable {
            \(raw: casesCode)
        }
        """
    }

    private func collectAllScenarioCases() -> [String] {
        var cases = ["success"]
        cases.append(contentsOf: extractErrorScenarioCases())
        cases.append(contentsOf: extractCustomScenarioCases())
        return cases
    }

    private func extractErrorScenarioCases() -> [String] {
        args.errorExamples
            .sorted(by: { $0.key < $1.key })
            .map { statusCode, _ in
                getCaseNameForStatusCode(statusCode)
            }
            .filter { !["success"].contains($0) }
    }

    private func extractCustomScenarioCases() -> [String] {
        args.testScenarios.filter { scenario in
            !["success"].contains(scenario) &&
                !extractErrorScenarioCases().contains(scenario)
        }
    }
}

extension TestGenerator {
    private func generateMockResponseMethod() -> DeclSyntax {
        let switchCases = [
            generateSuccessCase(),
            generateErrorCases(),
            generateDefaultCase()
        ].flatMap { $0 }

        let switchBody = switchCases.joined(separator: "\n        ")

        return """
        public func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
            switch scenario {
            \(raw: switchBody)
            }
        }
        """
    }

    private func generateSuccessCase() -> [String] {
        [createMockResponseCase(
            scenario: "success",
            json: MockJSON.success,
            statusCode: HTTPStatusCode.ok
        )]
    }

    private func generateErrorCases() -> [String] {
        args.errorExamples
            .sorted(by: { $0.key < $1.key })
            .map { statusCode, jsonExample in
                let caseName = getCaseNameForStatusCode(statusCode)
                let escapedJSON = escapeJSON(jsonExample)
                return createMockResponseCase(
                    scenario: caseName,
                    json: escapedJSON,
                    statusCode: statusCode
                )
            }
    }

    private func generateDefaultCase() -> [String] {
        ["""
        default:
            return (nil, nil, URLError(.unknown))
        """]
    }

    private func createMockResponseCase(
        scenario: String,
        json: String,
        statusCode: String
    ) -> String {
        """
        case .\(scenario):
            let json = "\(json)"
            let data = json.data(using: .utf8)
            let response = HTTPURLResponse(
                url: URL(string: "\(MockConstants.baseURL)")!,
                statusCode: \(statusCode),
                httpVersion: nil,
                headerFields: nil
            )
            return (data, response, nil)
        """
    }
}

extension TestGenerator {
    private func getCaseNameForStatusCode(_ statusCode: String) -> String {
        guard let code = Int(statusCode) else {
            return "error\(statusCode)"
        }

        return HTTPStatusCode.caseName(for: code)
    }

    private func escapeJSON(_ json: String) -> String {
        JSONEscaper.escape(json)
    }
}

private enum MockConstants {
    static let baseURL = "https://example.com"
}

private enum MockJSON {
    static let success = #"{\\"id\\": 1, \\"title\\": \\"Mock Title\\"}"#
}

private enum HTTPStatusCode {
    static let success = "200"

    static func caseName(for code: Int) -> String {
        switch code {
        case 400: return "badRequest"
        case 401: return "unauthorized"
        case 403: return "forbidden"
        case 404: return "notFound"
        case 500: return "serverError"
        case 503: return "serviceUnavailable"
        default: return "error\(code)"
        }
    }
}

private enum JSONEscaper {
    static func escape(_ json: String) -> String {
        json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
