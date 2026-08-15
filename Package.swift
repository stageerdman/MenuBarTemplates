// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MenuBarTemplates",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MenuBarTemplates", targets: ["MenuBarTemplates"]),
        .executable(name: "ResolverTests", targets: ["ResolverTests"]),
        .library(name: "EmailTemplateCore", targets: ["EmailTemplateCore"])
    ],
    targets: [
        .target(name: "EmailTemplateCore"),
        .executableTarget(
            name: "MenuBarTemplates",
            dependencies: ["EmailTemplateCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("WebKit")
            ]
        ),
        .executableTarget(
            name: "ResolverTests",
            dependencies: ["EmailTemplateCore"]
        )
    ]
)
