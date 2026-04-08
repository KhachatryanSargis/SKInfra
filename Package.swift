// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SKInfra",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SKCore", targets: ["SKCore"]),
        .library(name: "SKDI", targets: ["SKDI"]),
        .library(name: "SKNavigation", targets: ["SKNavigation"]),
        .library(name: "SKStorage", targets: ["SKStorage"])
    ],
    targets: [
        // MARK: - SKCore
        .target(
            name: "SKCore",
            path: "Sources/SKCore"
        ),
        .testTarget(
            name: "SKCoreTests",
            dependencies: ["SKCore"],
            path: "Tests/SKCoreTests"
        ),

        // MARK: - SKDI
        .target(
            name: "SKDI",
            dependencies: ["SKCore"],
            path: "Sources/SKDI"
        ),
        .testTarget(
            name: "SKDITests",
            dependencies: ["SKDI"],
            path: "Tests/SKDITests"
        ),

        // MARK: - SKNavigation
        .target(
            name: "SKNavigation",
            dependencies: ["SKCore"],
            path: "Sources/SKNavigation"
        ),
        .testTarget(
            name: "SKNavigationTests",
            dependencies: ["SKNavigation"],
            path: "Tests/SKNavigationTests"
        ),

        // MARK: - SKStorage
        .target(
            name: "SKStorage",
            dependencies: ["SKCore"],
            path: "Sources/SKStorage"
        ),
        .testTarget(
            name: "SKStorageTests",
            dependencies: ["SKStorage"],
            path: "Tests/SKStorageTests"
        )
    ]
)
