import Foundation
import ESPHomeSwiftCore

// Re-export Matter configuration types from ESPHomeSwiftCore
@_exported import struct ESPHomeSwiftCore.MatterConfig
@_exported import struct ESPHomeSwiftCore.CommissioningConfig
@_exported import struct ESPHomeSwiftCore.ThreadConfig
@_exported import struct ESPHomeSwiftCore.MatterNetworkConfig
@_exported import struct ESPHomeSwiftCore.MDNSConfig

/// Extended Matter configuration functionality
public extension MatterConfig {
    /// Get the Matter device type enum from string
    var matterDeviceType: MatterDeviceType? {
        return MatterDeviceType(rawValue: deviceType)
    }
    
    /// Get the Matter transport enum from network config
    var matterTransport: MatterTransport {
        guard let network = network else { return .wifi }
        return MatterTransport(rawValue: network.transport) ?? .wifi
    }
    
    /// Validate configuration for the given board
    /// - Parameter board: ESP32 board identifier
    /// - Throws: MatterValidationError if configuration is invalid
    func validate(for board: String) throws {
        try MatterValidator.validate(self, for: board)
    }
    
    /// Create a new Matter configuration with validated device type
    /// - Parameters:
    ///   - deviceType: Matter device type
    ///   - enabled: Enable Matter support
    ///   - vendorId: Vendor ID
    ///   - productId: Product ID
    ///   - commissioning: Commissioning configuration
    ///   - thread: Thread configuration
    ///   - network: Network configuration
    /// - Returns: New MatterConfig instance
    static func create(
        deviceType: MatterDeviceType,
        enabled: Bool = true,
        vendorId: UInt16 = 0xFFF1,
        productId: UInt16 = 0x8000,
        commissioning: CommissioningConfig? = nil,
        thread: ThreadConfig? = nil,
        network: MatterNetworkConfig? = nil
    ) -> MatterConfig {
        return MatterConfig(
            enabled: enabled,
            deviceType: deviceType.rawValue,
            vendorId: vendorId,
            productId: productId,
            commissioning: commissioning,
            thread: thread,
            network: network
        )
    }
}

/// Matter transport protocol options
public enum MatterTransport: String, Codable, CaseIterable {
    case wifi = "wifi"
    case thread = "thread"
    case ethernet = "ethernet"
}

/// Extended Thread configuration functionality
public extension ThreadConfig {
    /// Validate Thread configuration parameters
    /// - Parameter board: Target ESP32 board
    /// - Throws: MatterValidationError if invalid
    func validate(for board: String) throws {
        // Delegate to MatterValidator for detailed validation
        let dummyMatterConfig = MatterConfig(
            enabled: true,
            deviceType: "on_off_light",
            thread: self
        )
        try MatterValidator.validate(dummyMatterConfig, for: board)
    }
    
    /// Create Thread configuration from operational dataset
    /// - Parameter dataset: Thread operational dataset (hex string)
    /// - Returns: ThreadConfig with dataset
    static func fromDataset(_ dataset: String) -> ThreadConfig {
        return ThreadConfig(enabled: true, dataset: dataset)
    }
    
    /// Create Thread configuration with network parameters
    /// - Parameters:
    ///   - networkName: Thread network name
    ///   - networkKey: Network key (32 hex characters)
    ///   - channel: Channel number (11-26)
    ///   - panId: PAN ID
    /// - Returns: ThreadConfig with specified parameters
    static func create(
        networkName: String,
        networkKey: String,
        channel: UInt8,
        panId: UInt16,
        extPanId: String? = nil
    ) -> ThreadConfig {
        return ThreadConfig(
            enabled: true,
            networkName: networkName,
            extPanId: extPanId,
            networkKey: networkKey,
            channel: channel,
            panId: panId
        )
    }
}

/// Extended commissioning configuration functionality  
public extension CommissioningConfig {
    /// Generate QR code payload from commissioning parameters
    /// - Returns: QR code payload string (if implementable)
    func generateQRCode() -> String {
        // This would generate a Matter QR code payload
        // For now, return placeholder - requires Matter SDK integration
        return "MT:PLACEHOLDER_QR_CODE"
    }
    
    /// Generate manual pairing code from commissioning parameters
    /// - Returns: Manual pairing code string
    func generateManualPairingCode() -> String {
        // This would generate an 11-digit manual pairing code
        // For now, return placeholder - requires Matter SDK integration
        return "12345-67890"
    }
    
    /// Create commissioning configuration with generated codes
    /// - Parameters:
    ///   - discriminator: Commissioning discriminator
    ///   - passcode: Setup passcode
    /// - Returns: CommissioningConfig with generated codes
    static func withGeneratedCodes(
        discriminator: UInt16 = 3840,
        passcode: UInt32 = 20202021
    ) -> CommissioningConfig {
        let config = CommissioningConfig(discriminator: discriminator, passcode: passcode)
        return CommissioningConfig(
            discriminator: discriminator,
            passcode: passcode,
            manualPairingCode: config.generateManualPairingCode(),
            qrCodePayload: config.generateQRCode()
        )
    }
}