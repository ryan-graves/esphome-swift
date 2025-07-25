// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ESPHomeSwift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Main CLI executable
        .executable(
            name: "esphome-swift",
            targets: ["CLI"]
        ),
        // Core library for external use
        .library(
            name: "ESPHomeSwiftCore",
            targets: ["ESPHomeSwiftCore"]
        ),
        // Code generation library
        .library(
            name: "CodeGeneration",
            targets: ["CodeGeneration"]
        ),
        // Component library
        .library(
            name: "ComponentLibrary",
            targets: ["ComponentLibrary"]
        ),
        // Matter protocol support library
        .library(
            name: "MatterSupport",
            targets: ["MatterSupport"]
        )
    ],
    dependencies: [
        // YAML parsing
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        // Command line argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1"),
        // Web server for dashboard
        .package(url: "https://github.com/vapor/vapor.git", from: "4.102.0"),
        // File system utilities
        .package(url: "https://github.com/apple/swift-system.git", from: "1.4.0")
    ],
    targets: [
        // Core configuration and validation engine
        .target(
            name: "ESPHomeSwiftCore",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SystemPackage", package: "swift-system")
            ]
        ),
        
        // Code generation engine
        .target(
            name: "CodeGeneration",
            dependencies: [
                "ESPHomeSwiftCore",
                "ComponentLibrary",
                "MatterSupport",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SystemPackage", package: "swift-system")
            ]
        ),
        
        // Built-in component definitions
        .target(
            name: "ComponentLibrary",
            dependencies: [
                "ESPHomeSwiftCore"
            ]
        ),
        
        // Matter protocol support
        .target(
            name: "MatterSupport",
            dependencies: [
                "ESPHomeSwiftCore",
                "ComponentLibrary"
            ]
        ),
        
        // Command line interface
        .executableTarget(
            name: "CLI",
            dependencies: [
                "ESPHomeSwiftCore",
                "CodeGeneration",
                "ComponentLibrary",
                "WebDashboard",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        
        // Web dashboard for monitoring
        .target(
            name: "WebDashboard",
            dependencies: [
                "ESPHomeSwiftCore",
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        
        // Tests
        .testTarget(
            name: "ESPHomeSwiftCoreTests",
            dependencies: ["ESPHomeSwiftCore"]
        ),
        .testTarget(
            name: "CodeGenerationTests",
            dependencies: ["CodeGeneration"]
        ),
        .testTarget(
            name: "ComponentLibraryTests",
            dependencies: ["ComponentLibrary"]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["CLI"]
        ),
        .testTarget(
            name: "MatterSupportTests",
            dependencies: ["MatterSupport", "ESPHomeSwiftCore", "ComponentLibrary"]
        )
    ]
)