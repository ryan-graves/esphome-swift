import Foundation
import Yams
import Logging

/// Configuration parser for ESPHome Swift YAML files
public class ConfigurationParser {
    private let logger = Logger(label: "ConfigurationParser")
    
    public init() {}
    
    /// Parse YAML configuration from string
    public func parse(yaml: String) throws -> ESPHomeConfiguration {
        logger.info("Parsing YAML configuration")
        
        do {
            let decoder = YAMLDecoder()
            let configuration = try decoder.decode(ESPHomeConfiguration.self, from: yaml)
            
            try validate(configuration: configuration)
            logger.info("Configuration parsed and validated successfully")
            
            return configuration
        } catch let error as DecodingError {
            logger.error("YAML parsing failed: \(error)")
            throw ConfigurationError.yamlParsingError(error)
        } catch let error as ValidationError {
            logger.error("Configuration validation failed: \(error)")
            throw error
        } catch {
            logger.error("Unexpected error during parsing: \(error)")
            throw ConfigurationError.unexpectedError(error)
        }
    }
    
    /// Parse YAML configuration from file
    public func parseFile(at path: String) throws -> ESPHomeConfiguration {
        logger.info("Loading configuration file: \(path)")
        
        guard let data = FileManager.default.contents(atPath: path) else {
            throw ConfigurationError.fileNotFound(path)
        }
        
        guard let yaml = String(data: data, encoding: .utf8) else {
            throw ConfigurationError.invalidFileEncoding(path)
        }
        
        return try parse(yaml: yaml)
    }
    
    /// Validate configuration structure and values
    private func validate(configuration: ESPHomeConfiguration) throws {
        let validator = ConfigurationValidator()
        try validator.validate(configuration)
    }
}

/// Configuration validation errors
public enum ConfigurationError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFileEncoding(String)
    case yamlParsingError(DecodingError)
    case unexpectedError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found: \(path)"
        case .invalidFileEncoding(let path):
            return "Invalid file encoding for: \(path)"
        case .yamlParsingError(let error):
            return "YAML parsing error: \(error.localizedDescription)"
        case .unexpectedError(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}

/// Configuration validation errors
public enum ValidationError: Error, LocalizedError {
    case invalidNodeName(String)
    case invalidBoardType(String)
    case invalidGPIOPin(String)
    case incompatibleComponentCombination(String)
    case missingRequiredProperty(String)
    case invalidPropertyValue(property: String, value: String, reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidNodeName(let name):
            return "Invalid node name '\(name)': must contain only lowercase letters, numbers, and underscores"
        case .invalidBoardType(let board):
            return "Invalid board type '\(board)': not supported for ESP32 RISC-V targets"
        case .invalidGPIOPin(let pin):
            return "Invalid GPIO pin '\(pin)': not available on selected board"
        case .incompatibleComponentCombination(let message):
            return "Incompatible component combination: \(message)"
        case .missingRequiredProperty(let property):
            return "Missing required property: \(property)"
        case .invalidPropertyValue(let property, let value, let reason):
            return "Invalid value '\(value)' for property '\(property)': \(reason)"
        }
    }
}

/// Configuration validator
public class ConfigurationValidator {
    private let logger = Logger(label: "ConfigurationValidator")
    
    public init() {}
    
    /// Validate complete configuration
    public func validate(_ configuration: ESPHomeConfiguration) throws {
        try validateCore(configuration.esphomeSwift)
        try validateESP32(configuration.esp32)
        
        if let wifi = configuration.wifi {
            try validateWiFi(wifi)
        }
        
        if let sensors = configuration.sensor {
            try validateSensors(sensors)
        }
        
        if let switches = configuration.`switch` {
            try validateSwitches(switches)
        }
        
        if let lights = configuration.light {
            try validateLights(lights)
        }
        
        if let binarySensors = configuration.binary_sensor {
            try validateBinarySensors(binarySensors)
        }
    }
    
    /// Validate core configuration
    private func validateCore(_ config: CoreConfig) throws {
        // Node name validation
        let namePattern = "^[a-z0-9_]+$"
        let nameRegex = try NSRegularExpression(pattern: namePattern)
        let nameRange = NSRange(location: 0, length: config.name.utf16.count)
        
        if nameRegex.firstMatch(in: config.name, options: [], range: nameRange) == nil {
            throw ValidationError.invalidNodeName(config.name)
        }
        
        logger.debug("Core configuration validated")
    }
    
    /// Validate ESP32 configuration
    private func validateESP32(_ config: ESP32Config) throws {
        // Validate board type for RISC-V support
        let supportedBoards = [
            "esp32-c3-devkitm-1",
            "esp32-c3-devkitc-02",
            "esp32-c6-devkitc-1",
            "esp32-h2-devkitm-1",
            "esp32-p4-function-ev-board"
        ]
        
        if !supportedBoards.contains(config.board) {
            logger.warning("Board '\(config.board)' may not support Embedded Swift")
        }
        
        // Validate framework
        if config.framework.type == .arduino {
            logger.warning("Arduino framework may have limited Embedded Swift support")
        }
        
        logger.debug("ESP32 configuration validated")
    }
    
    /// Validate WiFi configuration
    private func validateWiFi(_ config: WiFiConfig) throws {
        if config.ssid.isEmpty {
            throw ValidationError.missingRequiredProperty("wifi.ssid")
        }
        
        if config.password.isEmpty {
            throw ValidationError.missingRequiredProperty("wifi.password")
        }
        
        logger.debug("WiFi configuration validated")
    }
    
    /// Validate sensor configurations
    private func validateSensors(_ sensors: [SensorConfig]) throws {
        for (index, sensor) in sensors.enumerated() {
            try validateSensor(sensor, index: index)
        }
        
        logger.debug("Sensor configurations validated")
    }
    
    /// Validate individual sensor
    private func validateSensor(_ sensor: SensorConfig, index: Int) throws {
        // Validate platform-specific requirements
        switch sensor.platform {
        case "dht":
            guard sensor.pin != nil else {
                throw ValidationError.missingRequiredProperty("sensor[\(index)].pin")
            }
            guard sensor.model != nil else {
                throw ValidationError.missingRequiredProperty("sensor[\(index)].model")
            }
        case "gpio":
            guard sensor.pin != nil else {
                throw ValidationError.missingRequiredProperty("sensor[\(index)].pin")
            }
        default:
            logger.warning("Unknown sensor platform: \(sensor.platform)")
        }
    }
    
    /// Validate switch configurations
    private func validateSwitches(_ switches: [SwitchConfig]) throws {
        for (index, switchConfig) in switches.enumerated() {
            if switchConfig.platform == "gpio" {
                guard switchConfig.pin != nil else {
                    throw ValidationError.missingRequiredProperty("switch[\(index)].pin")
                }
            }
        }
        
        logger.debug("Switch configurations validated")
    }
    
    /// Validate light configurations
    private func validateLights(_ lights: [LightConfig]) throws {
        for (index, light) in lights.enumerated() {
            switch light.platform {
            case "binary":
                guard light.pin != nil else {
                    throw ValidationError.missingRequiredProperty("light[\(index)].pin")
                }
            case "rgb":
                guard light.redPin != nil && light.greenPin != nil && light.bluePin != nil else {
                    throw ValidationError.missingRequiredProperty("light[\(index)] RGB pins")
                }
            default:
                logger.warning("Unknown light platform: \(light.platform)")
            }
        }
        
        logger.debug("Light configurations validated")
    }
    
    /// Validate binary sensor configurations
    private func validateBinarySensors(_ binarySensors: [BinarySensorConfig]) throws {
        for (index, sensor) in binarySensors.enumerated() {
            if sensor.platform == "gpio" {
                guard sensor.pin != nil else {
                    throw ValidationError.missingRequiredProperty("binary_sensor[\(index)].pin")
                }
            }
        }
        
        logger.debug("Binary sensor configurations validated")
    }
}