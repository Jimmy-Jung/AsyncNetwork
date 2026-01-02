import ProjectDescription

/// API 문서 앱 템플릿
let template = Template(
    description: "AsyncNetwork API Documentation App Template",
    attributes: [
        .required("name"),
        .optional("organization", default: "com.asyncnetwork"),
        .optional("deploymentTarget", default: "15.0")
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

        // Info.plist
        .file(
            path: "\(Template.Attribute.required("name"))/Resources/Info.plist",
            templatePath: "Info.plist"
        ),

        // README
        .file(
            path: "\(Template.Attribute.required("name"))/README.md",
            templatePath: "README.stencil"
        )
    ]
)
