import Foundation

/// ESPHome Swift Core - Configuration parsing and validation
///
/// This module provides the core functionality for parsing and validating
/// ESPHome Swift configuration files, including YAML parsing, schema validation,
/// and type-safe configuration structures.

// Re-export main types for convenience
@_exported import struct Foundation.URL
@_exported import protocol Foundation.LocalizedError

/// Library version information
public struct ESPHomeSwiftCoreVersion {
    public static let current = "0.1.0"
    public static let minimumSwiftVersion = "6.0"
    public static let supportedESP32Platforms = [
        "esp32-c3-devkitm-1",
        "esp32-c3-devkitc-02", 
        "esp32-c6-devkitc-1",
        "esp32-h2-devkitm-1",
        "esp32-p4-function-ev-board"
    ]
}

/// Main entry point for configuration operations
public final class ESPHomeSwiftCore {
    public static let shared = ESPHomeSwiftCore()
    
    public let parser: ConfigurationParser
    public let validator: ConfigurationValidator
    
    private init() {
        self.parser = ConfigurationParser()
        self.validator = ConfigurationValidator()
    }
    
    /// Parse configuration from YAML string
    public func parseConfiguration(yaml: String) throws -> ESPHomeConfiguration {
        return try parser.parse(yaml: yaml)
    }
    
    /// Parse configuration from file
    public func parseConfiguration(file: String) throws -> ESPHomeConfiguration {
        return try parser.parseFile(at: file)
    }
    
    /// Validate configuration
    public func validateConfiguration(_ config: ESPHomeConfiguration) throws {
        try validator.validate(config)
    }
}