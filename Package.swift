// swift-tools-version: 6.1

import PackageDescription

// MARK: - Lint Plugin
//
// SwiftLintBuildToolPlugin runs on every `swift build` and surfaces
// violations as compiler warnings — visible directly in Xcode and in
// the terminal. CI uses a dedicated `swiftlint --strict` job for the
// hard gate; this plugin is the in-editor feedback loop.
//
// Attached to every target via the helper below.
let lintPlugins: [Target.PluginUsage] = [
    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
]

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
        .library(name: "SKAuth", targets: ["SKAuth"]),
        .library(name: "SKMonetization", targets: ["SKMonetization"]),
        .library(name: "SKInfraTesting", targets: ["SKInfraTesting"])
    ],
    dependencies: [
        // Build-time only — does not link into consumers' binaries.
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.57.0"),
        // Runtime — linked only by the SKAuth product. Consumers that
        // don't depend on SKAuth get no Firebase in their binary.
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        // Runtime — linked only by the SKMonetization product.
        .package(url: "https://github.com/RevenueCat/purchases-ios", from: "5.0.0")
    ],
    targets: [
        // MARK: - SKCore
        .target(
            name: "SKCore",
            path: "Sources/SKCore",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKCoreTests",
            dependencies: ["SKCore", "SKInfraTesting"],
            path: "Tests/SKCoreTests",
            plugins: lintPlugins
        ),

        // MARK: - SKDI
        .target(
            name: "SKDI",
            dependencies: ["SKCore"],
            path: "Sources/SKDI",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKDITests",
            dependencies: ["SKDI", "SKInfraTesting"],
            path: "Tests/SKDITests",
            plugins: lintPlugins
        ),

        // MARK: - SKNavigation
        .target(
            name: "SKNavigation",
            dependencies: ["SKCore"],
            path: "Sources/SKNavigation",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKNavigationTests",
            dependencies: ["SKNavigation", "SKInfraTesting"],
            path: "Tests/SKNavigationTests",
            plugins: lintPlugins
        ),

        // MARK: - SKStorage
        .target(
            name: "SKStorage",
            dependencies: ["SKCore"],
            path: "Sources/SKStorage",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKStorageTests",
            dependencies: ["SKStorage", "SKInfraTesting"],
            path: "Tests/SKStorageTests",
            plugins: lintPlugins
        ),

        // MARK: - SKAnalytics
        .target(
            name: "SKAnalytics",
            dependencies: ["SKCore"],
            path: "Sources/SKAnalytics",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKAnalyticsTests",
            dependencies: ["SKAnalytics", "SKInfraTesting"],
            path: "Tests/SKAnalyticsTests",
            plugins: lintPlugins
        ),

        // MARK: - SKAuth
        .target(
            name: "SKAuth",
            dependencies: [
                "SKCore",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            path: "Sources/SKAuth",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKAuthTests",
            dependencies: ["SKAuth", "SKInfraTesting"],
            path: "Tests/SKAuthTests",
            plugins: lintPlugins
        ),

        // MARK: - SKMonetization
        .target(
            name: "SKMonetization",
            dependencies: [
                "SKCore",
                .product(name: "RevenueCat", package: "purchases-ios")
            ],
            path: "Sources/SKMonetization",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKMonetizationTests",
            dependencies: ["SKMonetization", "SKInfraTesting"],
            path: "Tests/SKMonetizationTests",
            plugins: lintPlugins
        ),

        // MARK: - SKInfraTesting
        .target(
            name: "SKInfraTesting",
            dependencies: ["SKCore"],
            path: "Sources/SKInfraTesting",
            plugins: lintPlugins
        ),
        .testTarget(
            name: "SKInfraTestingTests",
            dependencies: ["SKInfraTesting"],
            path: "Tests/SKInfraTestingTests",
            plugins: lintPlugins
        )
    ]
)
