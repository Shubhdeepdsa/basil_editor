// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EditorLab",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EditorLab",
            targets: ["EditorLab"]
        )
    ],
    targets: [
        .target(
            name: "EditorLab"
        ),
        .testTarget(
            name: "EditorLabTests",
            dependencies: ["EditorLab"]
        )
    ]
)
