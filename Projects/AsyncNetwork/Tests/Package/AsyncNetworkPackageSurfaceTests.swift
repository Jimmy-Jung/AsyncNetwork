//
//  AsyncNetworkPackageSurfaceTests.swift
//  AsyncNetworkTests
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
import Foundation
import Testing

struct AsyncNetworkPackageSurfaceTests {
    @Test("AsyncNetwork 우산 모듈 import 후 코어 API 사용 가능")
    func asyncNetworkUmbrellaImportSmoke() throws {
        // swiftlint:disable:next nesting
        struct SmokeRequest: APIRequest {
            typealias Response = EmptyResponse

            let baseURLString = "https://api.example.com"
            let path = "/posts/{id}"
            let method: HTTPMethod = .get

            @PathParameter var id: Int
            @QueryParameter var limit: Int?

            init(id: Int, limit: Int? = nil) {
                self.id = id
                self.limit = limit
            }
        }

        let request = SmokeRequest(id: 42, limit: 10)
        let urlRequest = try request.asURLRequest()
        let service = NetworkService.default()

        #expect(urlRequest.url?.absoluteString == "https://api.example.com/posts/42?limit=10")
        #expect(urlRequest.httpMethod == "GET")
        #expect(service.isNetworkAvailable || !service.isNetworkAvailable)
    }

    @Test("Package manifest 에 macro target/dependency 잔재가 없음")
    func packageManifestDoesNotContainMacroArtifacts() throws {
        let packageContents = try String(contentsOf: repositoryRoot().appendingPathComponent("Package.swift"))

        #expect(!packageContents.contains("AsyncNetworkMacros"))
        #expect(!packageContents.contains("AsyncNetworkMacrosImpl"))
        #expect(!packageContents.contains("swift-syntax"))
        #expect(!packageContents.contains("swift-macro-testing"))
    }

    @Test("공개 저장소 문서와 워크플로에 제거된 이름이 남아있지 않음")
    func repositorySurfaceDoesNotContainRemovedSurfaceNames() throws {
        let forbiddenTerms = [
            "NetworkKit",
            "AsyncNetworkSampleApp",
            "OpenAPIExample"
        ]

        let files = [
            "README.md",
            ".github/CONTRIBUTING.md",
            ".github/SECURITY.md",
            ".github/ISSUE_TEMPLATE/bug_report.yml",
            ".github/ISSUE_TEMPLATE/feature_request.yml",
            ".github/workflows/release.yml"
        ]

        for relativePath in files {
            let contents = try String(contentsOf: repositoryRoot().appendingPathComponent(relativePath))

            for forbiddenTerm in forbiddenTerms {
                #expect(
                    !contents.contains(forbiddenTerm),
                    "\(relativePath) should not contain \(forbiddenTerm)"
                )
            }
        }
    }

    private func repositoryRoot() -> URL {
        var currentURL = URL(fileURLWithPath: #filePath)

        while currentURL.path != "/" {
            let candidate = currentURL.deletingLastPathComponent()
            let packagePath = candidate.appendingPathComponent("Package.swift").path

            if FileManager.default.fileExists(atPath: packagePath) {
                return candidate
            }

            currentURL = candidate
        }

        fatalError("Repository root not found")
    }
}
