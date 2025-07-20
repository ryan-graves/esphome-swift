// Swift Embedded Code Generation Module
// Handles the transition from YAML configuration to Swift Embedded firmware

import Foundation
import ESPHomeSwiftCore

/// Main entry point for Swift Embedded code generation
public struct SwiftEmbeddedGen {
    
    /// Generate a complete Swift Embedded firmware project from ESPHome configuration
    public static func generateProject(
        from configuration: ESPHomeConfiguration,
        outputDirectory: String
    ) throws -> GeneratedSwiftPackage {
        let generator = SwiftPackageGenerator()
        return try generator.generatePackage(
            from: configuration,
            outputDirectory: outputDirectory
        )
    }
    
    /// Validate that a configuration is compatible with Swift Embedded mode
    public static func validateConfiguration(
        _ configuration: ESPHomeConfiguration
    ) throws {
        // Framework type is always Swift Embedded now
        
        // Validate board support
        let supportedBoards = [
            "esp32-c3-devkitm-1",
            "esp32-c6-devkitc-1", 
            "esp32-h2-devkitm-1",
            "esp32-p4-devkit"
        ]
        
        guard supportedBoards.contains(configuration.esp32.board) else {
            throw ValidationError.unsupportedBoard(
                "Board '\(configuration.esp32.board)' not supported. " +
                "Supported boards: \(supportedBoards.joined(separator: ", "))"
            )
        }
        
        // Validate components
        try validateComponents(configuration)
    }
    
    private static func validateComponents(_ config: ESPHomeConfiguration) throws {
        // Check sensor platforms
        if let sensors = config.sensor {
            for sensor in sensors {
                let supportedPlatforms = ["dht", "adc", "dallas"]
                guard supportedPlatforms.contains(sensor.platform) else {
                    throw ValidationError.unsupportedComponent(
                        "Sensor platform '\(sensor.platform)' not yet supported in Swift Embedded mode"
                    )
                }
            }
        }
        
        // Check switch platforms
        if let switches = config.`switch` {
            for sw in switches {
                guard sw.platform == "gpio" else {
                    throw ValidationError.unsupportedComponent(
                        "Switch platform '\(sw.platform)' not yet supported in Swift Embedded mode"
                    )
                }
            }
        }
        
        // Check light platforms
        if let lights = config.light {
            for light in lights {
                let supportedPlatforms = ["rgb", "monochromatic"]
                guard supportedPlatforms.contains(light.platform) else {
                    throw ValidationError.unsupportedComponent(
                        "Light platform '\(light.platform)' not yet supported in Swift Embedded mode"
                    )
                }
            }
        }
        
        // Check binary sensor platforms
        if let binarySensors = config.binary_sensor {
            for sensor in binarySensors {
                guard sensor.platform == "gpio" else {
                    throw ValidationError.unsupportedComponent(
                        "Binary sensor platform '\(sensor.platform)' not yet supported in Swift Embedded mode"
                    )
                }
            }
        }
    }
}

// MARK: - Validation Errors

public enum ValidationError: LocalizedError {
    case wrongFramework(String)
    case unsupportedBoard(String)
    case unsupportedComponent(String)
    case missingDependency(String)
    
    public var errorDescription: String? {
        switch self {
        case .wrongFramework(let message),
             .unsupportedBoard(let message),
             .unsupportedComponent(let message),
             .missingDependency(let message):
            return message
        }
    }
}