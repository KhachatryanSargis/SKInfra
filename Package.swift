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
        .library(name: "SKStorage", targets: ["SKStorage"]),
        .library(name: "SKAnalytics", targets: ["SKAnalytics"]),
        .library(name: "SKInfraTesting", targets: ["SKInfraTesting"])
    ],
    targets: [
        // MARK: - SKCore
        .target(
            name: "SKCore",
            path: "Sources/SKCore"
        ),
        .testTarget(
            name: "SKCoreTests",
            dependencies: ["SKCore", "SKInfraTesting"],
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
            dependencies: ["SKDI", "SKInfraTesting"],
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
            dependencies: ["SKNavigation", "SKInfraTesting"],
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
            dependencies: ["SKStorage", "SKInfraTesting"],
            path: "Tests/SKStorageTests"
        ),

        // MARK: - SKAnalytics
        .target(
            name: "SKAnalytics",
            dependencies: ["SKCore"],
            path: "Sources/SKAnalytics"
        ),
        .testTarget(
            name: "SKAnalyticsTests",
            dependencies: ["SKAnalytics", "SKInfraTesting"],
            path: "Tests/SKAnalyticsTests"
        ),

        // MARK: - SKInfraTesting
        .target(
            name: "SKInfraTesting",
            dependencies: ["SKCore"],
            path: "Sources/SKInfraTesting"
        ),
        .testTarget(
            name: "SKInfraTestingTests",
            dependencies: ["SKInfraTesting"],
            path: "Tests/SKInfraTestingTests"
        )
    ]
)
