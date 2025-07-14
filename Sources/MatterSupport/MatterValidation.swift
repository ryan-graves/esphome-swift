import Foundation
import ESPHomeSwiftCore

/// Matter-specific validation rules and error handling
public struct MatterValidator {
    
    /// Validates Matter configuration against ESP32 board capabilities
    /// - Parameters:
    ///   - config: Matter configuration to validate
    ///   - board: Target ESP32 board identifier
    /// - Throws: MatterValidationError if configuration is invalid
    public static func validate(_ config: MatterConfig, for board: String) throws {
        // Check if board supports Matter using centralized capabilities
        guard BoardCapabilities.supportsMatter(board) else {
            throw MatterValidationError.unsupportedBoard(
                board: board,
                reason: "Matter is only supported on ESP32-C6 and ESP32-H2 variants"
            )
        }
        
        // Validate commissioning configuration
        if let commissioning = config.commissioning {
            try validateCommissioning(commissioning)
        }
        
        // Validate Thread configuration for Thread-capable boards
        if let thread = config.thread {
            try validateThread(thread, for: board)
        }
        
        // Validate network transport configuration
        if let network = config.network {
            try validateNetwork(network, for: board, threadEnabled: config.thread?.enabled ?? false)
        }
        
        // Validate device type compatibility
        if let deviceType = config.matterDeviceType {
            try validateDeviceType(deviceType)
        } else {
            throw MatterValidationError.invalidIdentifier(
                type: "device_type",
                value: config.deviceType,
                reason: "Unknown Matter device type"
            )
        }
        
        // Validate vendor and product IDs
        try validateIdentifiers(vendorId: config.vendorId, productId: config.productId)
    }
    
    /// Validates commissioning configuration parameters
    private static func validateCommissioning(_ config: CommissioningConfig) throws {
        // Validate discriminator (12-bit value, 0-4095)
        guard config.discriminator <= 4095 else {
            throw MatterValidationError.invalidCommissioningParameter(
                parameter: "discriminator",
                value: String(config.discriminator),
                reason: "Discriminator must be between 0 and 4095"
            )
        }
        
        // Validate passcode (27-bit value, but with restrictions)
        guard config.passcode >= 1 && config.passcode <= 99999998 else {
            throw MatterValidationError.invalidCommissioningParameter(
                parameter: "passcode",
                value: String(config.passcode),
                reason: "Passcode must be between 1 and 99999998"
            )
        }
        
        // Check for invalid passcode patterns
        let invalidPasscodes: Set<UInt32> = [
            11111111, 22222222, 33333333, 44444444, 55555555,
            66666666, 77777777, 88888888, 99999999, 12345678,
            87654321
        ]
        
        guard !invalidPasscodes.contains(config.passcode) else {
            throw MatterValidationError.invalidCommissioningParameter(
                parameter: "passcode",
                value: String(config.passcode),
                reason: "Passcode cannot be a common pattern (sequential digits, all same digits, etc.)"
            )
        }
    }
    
    /// Validates Thread network configuration
    private static func validateThread(_ config: ThreadConfig, for board: String) throws {
        // Check if board supports Thread using centralized capabilities
        guard BoardCapabilities.supportsThread(board) else {
            let supportedBoards = BoardCapabilities.threadCapableBoards.joined(separator: ", ")
            throw MatterValidationError.unsupportedFeature(
                feature: "Thread",
                board: board,
                reason: "Thread networking requires ESP32-C6 or ESP32-H2. Supported boards: \(supportedBoards)"
            )
        }
        
        // Validate channel (802.15.4 channels 11-26)
        if let channel = config.channel {
            guard (11 ... 26).contains(channel) else {
                throw MatterValidationError.invalidThreadParameter(
                    parameter: "channel",
                    value: String(channel),
                    reason: "Thread channel must be between 11 and 26"
                )
            }
        }
        
        // Validate PAN ID (16-bit value, 0-0xFFFE)
        if let panId = config.panId {
            guard panId <= 0xFFFE else {
                throw MatterValidationError.invalidThreadParameter(
                    parameter: "pan_id",
                    value: String(panId),
                    reason: "PAN ID must be between 0 and 0xFFFE"
                )
            }
        }
        
        // Validate Extended PAN ID format (16 bytes hex)
        if let extPanId = config.extPanId {
            try validateHexString(extPanId, expectedLength: 32, parameterName: "ext_pan_id")
        }
        
        // Validate Network Key format (16 bytes hex)
        if let networkKey = config.networkKey {
            try validateHexString(networkKey, expectedLength: 32, parameterName: "network_key")
        }
        
        // Validate Thread dataset if provided
        if let dataset = config.dataset {
            // Thread Operational Dataset should be hex-encoded TLV
            guard !dataset.isEmpty else {
                throw MatterValidationError.invalidThreadParameter(
                    parameter: "dataset",
                    value: dataset,
                    reason: "Thread dataset cannot be empty"
                )
            }
            
            // Basic hex validation - should be even length hex string
            guard dataset.count % 2 == 0, dataset.allSatisfy(\.isHexDigit) else {
                throw MatterValidationError.invalidThreadParameter(
                    parameter: "dataset",
                    value: dataset,
                    reason: "Thread dataset must be a valid hex string"
                )
            }
        }
    }
    
    /// Validates network configuration
    private static func validateNetwork(_ config: MatterNetworkConfig, for board: String, threadEnabled: Bool) throws {
        // Validate transport selection
        switch config.transport {
        case "thread":
            guard threadEnabled else {
                throw MatterValidationError.inconsistentConfiguration(
                    reason: "Thread transport selected but Thread is not enabled"
                )
            }
            
        case "wifi":
            // WiFi is supported on all Matter-capable boards
            break
            
        case "ethernet":
            // Ethernet support would require additional hardware
            throw MatterValidationError.unsupportedFeature(
                feature: "Ethernet",
                board: board,
                reason: "Ethernet transport not currently supported"
            )
            
        default:
            throw MatterValidationError.inconsistentConfiguration(
                reason: "Unknown transport type: \(config.transport)"
            )
        }
    }
    
    /// Validates Matter device type
    private static func validateDeviceType(_ deviceType: MatterDeviceType) throws {
        // All defined device types are valid - this is mainly for future extensibility
        // Could add specific validation for device types that require certain hardware features
        
        switch deviceType {
        case .doorLock:
            // Door locks typically require secure elements or additional security features
            // For now, just document this requirement
            break
        case .thermostat:
            // Thermostats typically require temperature sensors
            break
        default:
            break
        }
    }
    
    /// Validates vendor and product identifiers
    private static func validateIdentifiers(vendorId: UInt16, productId: UInt16) throws {
        // Vendor ID 0xFFF1-0xFFF4 are reserved for testing
        // Production devices should use assigned vendor IDs
        let testVendorIds: Set<UInt16> = [0xFFF1, 0xFFF2, 0xFFF3, 0xFFF4]
        
        if testVendorIds.contains(vendorId) {
            // This is just a warning for development - not an error
            // In production, developers should obtain a proper vendor ID
        }
        
        // Product ID 0x0000 is invalid
        guard productId != 0x0000 else {
            throw MatterValidationError.invalidIdentifier(
                type: "product_id",
                value: String(productId),
                reason: "Product ID cannot be 0x0000"
            )
        }
    }
    
    /// Validates hex string format
    private static func validateHexString(_ hexString: String, expectedLength: Int, parameterName: String) throws {
        guard hexString.count == expectedLength else {
            throw MatterValidationError.invalidThreadParameter(
                parameter: parameterName,
                value: hexString,
                reason: "Expected \(expectedLength) hex characters, got \(hexString.count)"
            )
        }
        
        guard hexString.allSatisfy(\.isHexDigit) else {
            throw MatterValidationError.invalidThreadParameter(
                parameter: parameterName,
                value: hexString,
                reason: "Must contain only hexadecimal characters (0-9, A-F)"
            )
        }
    }
}

/// Matter validation errors
public enum MatterValidationError: Error, LocalizedError {
    case unsupportedBoard(board: String, reason: String)
    case unsupportedFeature(feature: String, board: String, reason: String)
    case invalidCommissioningParameter(parameter: String, value: String, reason: String)
    case invalidThreadParameter(parameter: String, value: String, reason: String)
    case invalidIdentifier(type: String, value: String, reason: String)
    case inconsistentConfiguration(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedBoard(let board, let reason):
            return "Board '\(board)' does not support Matter: \(reason)"
        case .unsupportedFeature(let feature, let board, let reason):
            return "\(feature) not supported on '\(board)': \(reason)"
        case .invalidCommissioningParameter(let parameter, let value, let reason):
            return "Invalid commissioning parameter '\(parameter)' = '\(value)': \(reason)"
        case .invalidThreadParameter(let parameter, let value, let reason):
            return "Invalid Thread parameter '\(parameter)' = '\(value)': \(reason)"
        case .invalidIdentifier(let type, let value, let reason):
            return "Invalid \(type) '\(value)': \(reason)"
        case .inconsistentConfiguration(let reason):
            return "Inconsistent Matter configuration: \(reason)"
        }
    }
}

private extension Character {
    var isHexDigit: Bool {
        return ("0" ... "9").contains(self) || ("A" ... "F").contains(self) || ("a" ... "f").contains(self)
    }
}