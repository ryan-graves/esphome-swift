// Swift Package Generator for ESPHome Swift Embedded Mode

import Foundation
import ESPHomeSwiftCore

/// Generates Swift Package structure for embedded firmware
public class SwiftPackageGenerator {
    private let componentAssembler = ComponentAssembler()
    
    public init() {}
    
    /// Generate complete Swift package from configuration
    public func generatePackage(
        from configuration: ESPHomeConfiguration,
        outputDirectory: String
    ) throws -> GeneratedSwiftPackage {
        let projectName = configuration.esphomeSwift.name
        let projectPath = "\(outputDirectory)/\(projectName)"
        
        // Create package structure
        try createPackageStructure(at: projectPath)
        
        // Generate Package.swift
        let packageManifest = try generatePackageManifest(
            configuration: configuration,
            projectName: projectName
        )
        
        // Generate main.swift with assembled components
        let mainSwift = try componentAssembler.assembleMainFile(
            configuration: configuration
        )
        
        // Generate component sources
        let componentSources = try generateComponentSources(
            configuration: configuration
        )
        
        // Write all files
        try writePackageFiles(
            projectPath: projectPath,
            manifest: packageManifest,
            mainSwift: mainSwift,
            componentSources: componentSources
        )
        
        // Copy HAL source files
        try copyHALSources(to: projectPath)
        
        return GeneratedSwiftPackage(
            path: projectPath,
            targetName: projectName,
            executableName: "\(projectName)Firmware"
        )
    }
    
    // MARK: - Private Methods
    
    private func createPackageStructure(at path: String) throws {
        let directories = [
            path,
            "\(path)/Sources",
            "\(path)/Sources/Firmware",
            "\(path)/Sources/Components",
            "\(path)/Sources/ESP32Hardware",
            "\(path)/Sources/SwiftEmbeddedCore",
            "\(path)/Resources"
        ]
        
        for directory in directories {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func generatePackageManifest(
        configuration: ESPHomeConfiguration,
        projectName: String
    ) throws -> String {
        let board = configuration.esp32.board
        let targetTriple = getTargetTriple(for: board)
        
        return """
        // swift-tools-version: 5.9
        // ESPHome Swift Generated Package - \(Date())
        
        import PackageDescription
        
        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v13)],
            products: [
                .executable(
                    name: "\(projectName)Firmware",
                    targets: ["Firmware"]
                )
            ],
            dependencies: [
                // ESPHome Swift framework dependencies
                // These would be resolved from the main project
            ],
            targets: [
                .executableTarget(
                    name: "Firmware",
                    dependencies: [
                        "Components",
                        "ESP32Hardware",
                        "SwiftEmbeddedCore"
                    ],
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded"),
                        .unsafeFlags([
                            "-target", "\(targetTriple)",
                            "-Xfrontend", "-function-sections",
                            "-Xfrontend", "-data-sections",
                            "-Xfrontend", "-disable-stack-protector"
                        ])
                    ],
                    linkerSettings: [
                        .unsafeFlags([
                            "-Xlinker", "-T",
                            "-Xlinker", "\\(Bundle.module.path(forResource: "esp32c6", ofType: "ld")!)"
                        ])
                    ]
                ),
                .target(
                    name: "Components",
                    dependencies: ["ESP32Hardware", "SwiftEmbeddedCore"],
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded")
                    ]
                ),
                .target(
                    name: "ESP32Hardware",
                    dependencies: [],
                    path: "Sources/ESP32Hardware",
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded")
                    ]
                ),
                .target(
                    name: "SwiftEmbeddedCore",
                    dependencies: ["ESP32Hardware"],
                    path: "Sources/SwiftEmbeddedCore",
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded")
                    ]
                )
            ]
        )
        """
    }
    
    private func generateComponentSources(
        configuration: ESPHomeConfiguration
    ) throws -> [ComponentSource] {
        var sources: [ComponentSource] = []
        
        // Generate component configuration structs
        let configSource = try generateComponentConfigs(configuration)
        sources.append(ComponentSource(
            fileName: "ComponentConfigs.swift",
            content: configSource
        ))
        
        // Copy required component implementations
        // In real implementation, this would copy actual component files
        
        return sources
    }
    
    private func generateComponentConfigs(
        _ configuration: ESPHomeConfiguration
    ) throws -> String {
        var configs = """
        // Auto-generated component configurations
        import Foundation
        import SwiftEmbeddedCore
        
        """
        
        // Generate config structs for each component type
        if let sensors = configuration.sensor {
            for sensor in sensors {
                configs += generateSensorConfig(sensor)
            }
        }
        
        if let switches = configuration.`switch` {
            for sw in switches {
                configs += generateSwitchConfig(sw)
            }
        }
        
        return configs
    }
    
    private func generateSensorConfig(_ sensor: SensorConfig) -> String {
        let id = sensor.id ?? "sensor_\(sensor.platform)"
        return """
        
        struct \(id.camelCased())Config {
            static let platform = "\(sensor.platform)"
            static let pin = \(sensor.pin.map { "GPIO(\($0.number))" } ?? "nil")
            static let name = "\(sensor.name ?? id)"
            static let updateInterval: UInt32 = \(parseInterval(sensor.updateInterval))
        }
        
        """
    }
    
    private func generateSwitchConfig(_ switch: SwitchConfig) -> String {
        let id = `switch`.id ?? "switch_\(`switch`.platform)"
        return """
        
        struct \(id.camelCased())Config {
            static let platform = "\(`switch`.platform)"
            static let pin = \(`switch`.pin.map { "GPIO(\($0.number))" } ?? "nil")
            static let name = "\(`switch`.name ?? id)"
            static let inverted = \(`switch`.inverted ?? false)
        }
        
        """
    }
    
    private func writePackageFiles(
        projectPath: String,
        manifest: String,
        mainSwift: String,
        componentSources: [ComponentSource]
    ) throws {
        // Write Package.swift
        let manifestURL = URL(fileURLWithPath: "\(projectPath)/Package.swift")
        try manifest.write(to: manifestURL, atomically: true, encoding: .utf8)
        
        // Write main.swift
        let mainURL = URL(fileURLWithPath: "\(projectPath)/Sources/Firmware/main.swift")
        try mainSwift.write(to: mainURL, atomically: true, encoding: .utf8)
        
        // Write component sources
        for source in componentSources {
            let sourceURL = URL(fileURLWithPath: "\(projectPath)/Sources/Components/\(source.fileName)")
            try source.content.write(to: sourceURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func getTargetTriple(for board: String) -> String {
        // All current ESP32 RISC-V boards use 32-bit architecture
        return "riscv32-none-none-eabi"
    }
    
    private func parseInterval(_ interval: String?) -> UInt32 {
        guard let interval = interval else { return 60 }
        
        if interval.hasSuffix("s") {
            return UInt32(interval.dropLast()) ?? 60
        } else if interval.hasSuffix("ms") {
            return (UInt32(interval.dropLast(2)) ?? 60000) / 1000
        }
        
        return UInt32(interval) ?? 60
    }
    
    private func copyHALSources(to projectPath: String) throws {
        let fileManager = FileManager.default
        
        // Get the path to the HAL modules in the main project
        // This assumes the generator is running from the main project directory
        let currentDirectory = fileManager.currentDirectoryPath
        let esp32HardwarePath = "\(currentDirectory)/Sources/ESP32Hardware"
        let swiftEmbeddedCorePath = "\(currentDirectory)/Sources/SwiftEmbeddedCore"
        
        // Copy ESP32Hardware files
        if fileManager.fileExists(atPath: esp32HardwarePath) {
            let hardwareFiles = try fileManager.contentsOfDirectory(atPath: esp32HardwarePath)
            for file in hardwareFiles where file.hasSuffix(".swift") {
                let sourcePath = "\(esp32HardwarePath)/\(file)"
                let destPath = "\(projectPath)/Sources/ESP32Hardware/\(file)"
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
            }
        }
        
        // Copy SwiftEmbeddedCore files
        if fileManager.fileExists(atPath: swiftEmbeddedCorePath) {
            let coreFiles = try fileManager.contentsOfDirectory(atPath: swiftEmbeddedCorePath)
            for file in coreFiles where file.hasSuffix(".swift") {
                let sourcePath = "\(swiftEmbeddedCorePath)/\(file)"
                let destPath = "\(projectPath)/Sources/SwiftEmbeddedCore/\(file)"
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
            }
        }
    }
}

/// Generated Swift package information
public struct GeneratedSwiftPackage {
    public let path: String
    public let targetName: String
    public let executableName: String
}

/// Component source file
struct ComponentSource {
    let fileName: String
    let content: String
}

// String extension for camelCase conversion is in ComponentAssembler.swift