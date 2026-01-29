// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DelamainStorage",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "DelamainStorage",
            targets: ["DelamainStorage"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/delamain-labs/DelamainCore.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DelamainStorage",
            dependencies: ["DelamainCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "DelamainStorageTests",
            dependencies: ["DelamainStorage"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
