// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-env",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "Env",
            targets: ["Env"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.4.0"),
    ],
    targets: [
        // Public library with macro declarations
        .target(
            name: "Env",
            dependencies: [
                "EnvMacros",
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),

        // Macro implementations (compiler plugin)
        .macro(
            name: "EnvMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // Tests
        .testTarget(
            name: "EnvMacrosTests",
            dependencies: [
                "Env",
                "EnvMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
