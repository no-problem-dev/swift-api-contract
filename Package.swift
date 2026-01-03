// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-api-contract",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        // Main library for API contract definitions
        .library(
            name: "APIContract",
            targets: ["APIContract"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: "602.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        // MARK: - Macro Implementation
        .macro(
            name: "APIContractMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // MARK: - Client Library
        .target(
            name: "APIContract",
            dependencies: ["APIContractMacros"]
        ),

        // MARK: - Tests
        .testTarget(
            name: "APIContractTests",
            dependencies: ["APIContract"]
        ),
        .testTarget(
            name: "APIContractMacrosTests",
            dependencies: [
                "APIContractMacros",
                "APIContract",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
