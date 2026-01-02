//
//  api-doc-app.swift
//  AsyncNetwork Template
//
//  Created by jimmy on 2026/01/02.
//

import ProjectDescription

/// AsyncNetwork API 문서 앱 템플릿
///
/// DocKitFactory를 사용한 현대적인 API 문서 앱을 생성합니다.
///
/// **사용법:**
/// ```bash
/// tuist scaffold api-doc-app --name MyAPIDoc --organization com.mycompany
/// ```
let template = Template(
    description: "AsyncNetwork API Documentation App Template with DocKit",
    attributes: [
        .required("name"),
        .optional("organization", default: "com.asyncnetwork"),
        .optional("author", default: "jimmy"),
        .optional("deploymentTarget", default: "17.0")
    ],
    items: [
        // Project.swift
        .file(
            path: "\(Template.Attribute.required("name"))/Project.swift",
            templatePath: "Project.stencil"
        ),

        // App Entry Point
        .file(
            path: "\(Template.Attribute.required("name"))/Sources/\(Template.Attribute.required("name"))App.swift",
            templatePath: "App.stencil"
        ),

        // API Configuration
        .file(
            path: "\(Template.Attribute.required("name"))/Sources/APIConfiguration.swift",
            templatePath: "APIConfiguration.stencil"
        ),

        // API Requests
        .file(
            path: "\(Template.Attribute.required("name"))/Sources/APIRequests.swift",
            templatePath: "APIRequests.stencil"
        ),

        // Models
        .file(
            path: "\(Template.Attribute.required("name"))/Sources/Models.swift",
            templatePath: "Models.stencil"
        ),

        // README
        .file(
            path: "\(Template.Attribute.required("name"))/README.md",
            templatePath: "README.stencil"
        )
    ]
)
