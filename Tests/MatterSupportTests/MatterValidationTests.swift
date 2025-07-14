import XCTest
@testable import MatterSupport
@testable import ESPHomeSwiftCore

final class MatterValidationTests: XCTestCase {
    
    func testBoardSupportValidation() throws {
        let config = MatterConfig(deviceType: "on_off_light")
        
        // Test supported boards
        let supportedBoards = [
            "esp32-c6-devkitc-1",
            "esp32-c6-devkitm-1", 
            "esp32-h2-devkitc-1",
            "esp32-h2-devkitm-1"
        ]
        
        for board in supportedBoards {
            XCTAssertNoThrow(try MatterValidator.validate(config, for: board),
                             "Board \(board) should support Matter")
        }
        
        // Test unsupported boards
        let unsupportedBoards = [
            "esp32-devkitc-v4",
            "esp32-s2-devkitc-1",
            "esp32-s3-devkitc-1",
            "esp32-c3-devkitc-02"
        ]
        
        for board in unsupportedBoards {
            XCTAssertThrowsError(try MatterValidator.validate(config, for: board)) { error in
                guard let matterError = error as? MatterValidationError else {
                    XCTFail("Expected MatterValidationError")
                    return
                }
                if case .unsupportedBoard(let boardName, _) = matterError {
                    XCTAssertEqual(boardName, board)
                }
            }
        }
    }
    
    func testCommissioningValidation() throws {
        // Test valid commissioning config
        let validCommissioning = CommissioningConfig(
            discriminator: 3840,
            passcode: 20202021
        )
        let config = MatterConfig(
            deviceType: "on_off_light",
            commissioning: validCommissioning
        )
        
        XCTAssertNoThrow(try MatterValidator.validate(config, for: "esp32-c6-devkitc-1"))
        
        // Test invalid discriminator (too large)
        let invalidDiscriminator = CommissioningConfig(
            discriminator: 5000, // > 4095
            passcode: 20202021
        )
        let configWithInvalidDiscriminator = MatterConfig(
            deviceType: "on_off_light",
            commissioning: invalidDiscriminator
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidDiscriminator, for: "esp32-c6-devkitc-1")) { error in
            guard let matterError = error as? MatterValidationError else {
                XCTFail("Expected MatterValidationError")
                return
            }
            if case .invalidCommissioningParameter(let parameter, _, _) = matterError {
                XCTAssertEqual(parameter, "discriminator")
            }
        }
        
        // Test invalid passcode (too small)
        let invalidPasscode = CommissioningConfig(
            discriminator: 3840,
            passcode: 0
        )
        let configWithInvalidPasscode = MatterConfig(
            deviceType: "on_off_light",
            commissioning: invalidPasscode
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidPasscode, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidCommissioningParameter(let parameter, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(parameter, "passcode")
            }
        }
        
        // Test invalid passcode patterns
        let invalidPasscodePatterns: [UInt32] = [
            11111111, 22222222, 33333333, 44444444, 55555555,
            66666666, 77777777, 88888888, 99999999, 12345678, 87654321
        ]
        
        for invalidCode in invalidPasscodePatterns {
            let invalidPattern = CommissioningConfig(
                discriminator: 3840,
                passcode: invalidCode
            )
            let configWithInvalidPattern = MatterConfig(
                deviceType: "on_off_light",
                commissioning: invalidPattern
            )
            
            XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidPattern, for: "esp32-c6-devkitc-1")) { error in
                XCTAssertTrue(error is MatterValidationError)
                if case .invalidCommissioningParameter(let parameter, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                    XCTAssertEqual(parameter, "passcode")
                }
            }
        }
    }
    
    func testThreadValidation() throws {
        // Test Thread on supported board
        let threadConfig = ThreadConfig(
            enabled: true,
            channel: 15,
            panId: 0x1234
        )
        let config = MatterConfig(
            deviceType: "on_off_light",
            thread: threadConfig
        )
        
        XCTAssertNoThrow(try MatterValidator.validate(config, for: "esp32-c6-devkitc-1"))
        XCTAssertNoThrow(try MatterValidator.validate(config, for: "esp32-h2-devkitc-1"))
        
        // Test Thread on unsupported board (should still pass overall validation, 
        // but Thread validation specifically should fail)
        XCTAssertThrowsError(try MatterValidator.validate(config, for: "esp32-devkitc-v4"))
        
        // Test invalid Thread channel
        let invalidChannelConfig = ThreadConfig(
            enabled: true,
            channel: 30 // > 26
        )
        let configWithInvalidChannel = MatterConfig(
            deviceType: "on_off_light",
            thread: invalidChannelConfig
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidChannel, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidThreadParameter(let parameter, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(parameter, "channel")
            }
        }
        
        // Test invalid PAN ID
        let invalidPanIdConfig = ThreadConfig(
            enabled: true,
            panId: 0xFFFF // > 0xFFFE
        )
        let configWithInvalidPanId = MatterConfig(
            deviceType: "on_off_light",
            thread: invalidPanIdConfig
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidPanId, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidThreadParameter(let parameter, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(parameter, "pan_id")
            }
        }
        
        // Test valid hex strings
        let validHexConfig = ThreadConfig(
            enabled: true,
            extPanId: "1234567890ABCDEF1234567890ABCDEF", // 32 hex chars
            networkKey: "FEDCBA0987654321FEDCBA0987654321" // 32 hex chars
        )
        let configWithValidHex = MatterConfig(
            deviceType: "on_off_light",
            thread: validHexConfig
        )
        
        XCTAssertNoThrow(try MatterValidator.validate(configWithValidHex, for: "esp32-c6-devkitc-1"))
        
        // Test invalid hex string length
        let invalidHexLengthConfig = ThreadConfig(
            enabled: true,
            extPanId: "1234567890ABCDEF" // 16 hex chars, should be 32
        )
        let configWithInvalidHexLength = MatterConfig(
            deviceType: "on_off_light",
            thread: invalidHexLengthConfig
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidHexLength, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidThreadParameter(let parameter, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(parameter, "ext_pan_id")
            }
        }
        
        // Test invalid hex characters
        let invalidHexCharsConfig = ThreadConfig(
            enabled: true,
            networkKey: "GHIJKLMNOPQRSTUV1234567890ABCDEF" // Contains G-V
        )
        let configWithInvalidHexChars = MatterConfig(
            deviceType: "on_off_light",
            thread: invalidHexCharsConfig
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(configWithInvalidHexChars, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidThreadParameter(let parameter, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(parameter, "network_key")
            }
        }
    }
    
    func testNetworkValidation() throws {
        // Test WiFi transport (should always work)
        let wifiNetwork = MatterNetworkConfig(transport: "wifi")
        let wifiConfig = MatterConfig(
            deviceType: "on_off_light",
            network: wifiNetwork
        )
        
        XCTAssertNoThrow(try MatterValidator.validate(wifiConfig, for: "esp32-c6-devkitc-1"))
        
        // Test Thread transport without Thread enabled
        let threadNetwork = MatterNetworkConfig(transport: "thread")
        let threadConfigWithoutThread = MatterConfig(
            deviceType: "on_off_light",
            network: threadNetwork
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(threadConfigWithoutThread, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .inconsistentConfiguration = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                // Expected
            } else {
                XCTFail("Should throw inconsistent configuration error")
            }
        }
        
        // Test Thread transport with Thread enabled
        let threadConfigWithThread = MatterConfig(
            deviceType: "on_off_light",
            thread: ThreadConfig(enabled: true),
            network: threadNetwork
        )
        
        XCTAssertNoThrow(try MatterValidator.validate(threadConfigWithThread, for: "esp32-c6-devkitc-1"))
        
        // Test Ethernet transport (not supported)
        let ethernetNetwork = MatterNetworkConfig(transport: "ethernet")
        let ethernetConfig = MatterConfig(
            deviceType: "on_off_light",
            network: ethernetNetwork
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(ethernetConfig, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .unsupportedFeature(let feature, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(feature, "Ethernet")
            }
        }
        
        // Test unknown transport
        let unknownNetwork = MatterNetworkConfig(transport: "unknown")
        let unknownConfig = MatterConfig(
            deviceType: "on_off_light",
            network: unknownNetwork
        )
        
        XCTAssertThrowsError(try MatterValidator.validate(unknownConfig, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .inconsistentConfiguration = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                // Expected
            } else {
                XCTFail("Should throw inconsistent configuration error")
            }
        }
    }
    
    func testDeviceTypeValidation() throws {
        // Test valid device type
        let validConfig = MatterConfig(deviceType: "on_off_light")
        XCTAssertNoThrow(try MatterValidator.validate(validConfig, for: "esp32-c6-devkitc-1"))
        
        // Test invalid device type
        let invalidConfig = MatterConfig(deviceType: "invalid_device_type")
        XCTAssertThrowsError(try MatterValidator.validate(invalidConfig, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidIdentifier(let type, let value, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(type, "device_type")
                XCTAssertEqual(value, "invalid_device_type")
            }
        }
    }
    
    func testIdentifierValidation() throws {
        // Test valid identifiers
        let validConfig = MatterConfig(
            deviceType: "on_off_light",
            vendorId: 0x1234,
            productId: 0x5678
        )
        XCTAssertNoThrow(try MatterValidator.validate(validConfig, for: "esp32-c6-devkitc-1"))
        
        // Test invalid product ID (0x0000)
        let invalidProductIdConfig = MatterConfig(
            deviceType: "on_off_light",
            vendorId: 0x1234,
            productId: 0x0000
        )
        XCTAssertThrowsError(try MatterValidator.validate(invalidProductIdConfig, for: "esp32-c6-devkitc-1")) { error in
            XCTAssertTrue(error is MatterValidationError)
            if case .invalidIdentifier(let type, _, _) = error as? MatterValidationError ?? MatterValidationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(type, "product_id")
            }
        }
        
        // Test test vendor IDs (should not throw, just log warning)
        let testVendorIds: [UInt16] = [0xFFF1, 0xFFF2, 0xFFF3, 0xFFF4]
        for testVendorId in testVendorIds {
            let testVendorConfig = MatterConfig(
                deviceType: "on_off_light",
                vendorId: testVendorId,
                productId: 0x8000
            )
            XCTAssertNoThrow(try MatterValidator.validate(testVendorConfig, for: "esp32-c6-devkitc-1"))
        }
    }
    
    func testMatterValidationErrorDescriptions() {
        let errors: [MatterValidationError] = [
            .unsupportedBoard(board: "esp32-s3", reason: "No Thread support"),
            .unsupportedFeature(feature: "Ethernet", board: "esp32-c6", reason: "Not implemented"),
            .invalidCommissioningParameter(parameter: "passcode", value: "0", reason: "Too small"),
            .invalidThreadParameter(parameter: "channel", value: "30", reason: "Out of range"),
            .invalidIdentifier(type: "vendor_id", value: "0", reason: "Invalid"),
            .inconsistentConfiguration(reason: "Thread transport without Thread config")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}