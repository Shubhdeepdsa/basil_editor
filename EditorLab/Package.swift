// swift-tools-version: 5.10

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
