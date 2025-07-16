import XCTest
@testable import MatterSupport
@testable import ESPHomeSwiftCore

final class MatterSetupPayloadTests: XCTestCase {
    
    // MARK: - Setup Payload Tests
    
    func testMatterSetupPayloadInitialization() {
        let payload = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3840,
            passcode: 20202021
        )
        
        XCTAssertEqual(payload.vendorId, 0xFFF1)
        XCTAssertEqual(payload.productId, 0x8000)
        XCTAssertEqual(payload.discriminator, 3840)
        XCTAssertEqual(payload.passcode, 20202021)
        XCTAssertEqual(payload.version, 0)
        XCTAssertEqual(payload.commissioningFlow, 0)
        XCTAssertEqual(payload.discoveryCapabilities, 0x04)
    }
    
    func testQRCodePayloadGeneration() {
        let payload = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3840,
            passcode: 20202021
        )
        
        let qrCode = payload.generateQRCodePayload()
        
        // QR code should start with "MT:"
        XCTAssertTrue(qrCode.hasPrefix("MT:"), "QR code should start with 'MT:'")
        
        // QR code should contain Base38 encoded data
        XCTAssertGreaterThan(qrCode.count, 3, "QR code should have more than just the prefix")
        
        // Should only contain valid Base38 characters after prefix
        let base38Chars = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.?")
        let payloadChars = Set(qrCode.dropFirst(3)) // Remove "MT:" prefix
        XCTAssertTrue(payloadChars.isSubset(of: base38Chars), "QR code payload should only contain Base38 characters")
    }
    
    func testQRCodeUniqueness() {
        let payload1 = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3840,
            passcode: 20202021
        )
        
        let payload2 = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3841, // Different discriminator
            passcode: 20202021
        )
        
        let qrCode1 = payload1.generateQRCodePayload()
        let qrCode2 = payload2.generateQRCodePayload()
        
        XCTAssertNotEqual(qrCode1, qrCode2, "Different configurations should generate different QR codes")
    }
    
    func testManualPairingCodeGeneration() throws {
        let payload = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3840,
            passcode: 20202021
        )
        
        let manualCode = try payload.generateManualPairingCode()
        
        // Manual code should have format: 11111-222222
        XCTAssertTrue(manualCode.contains("-"), "Manual pairing code should contain a hyphen")
        
        let parts = manualCode.split(separator: "-")
        XCTAssertEqual(parts.count, 2, "Manual pairing code should have two parts separated by hyphen")
        
        // First part should be 5 digits (Matter spec format)
        XCTAssertEqual(parts[0].count, 5, "First part should be 5 digits")
        XCTAssertTrue(parts[0].allSatisfy(\.isNumber), "First part should be all digits")
        
        // Second part should be 6 digits (includes check digit)
        XCTAssertEqual(parts[1].count, 6, "Second part should be 6 digits")
        XCTAssertTrue(parts[1].allSatisfy(\.isNumber), "Second part should be all digits")
    }
    
    // MARK: - Base38 Encoding Tests
    
    func testBase38Encoding() {
        let payload = MatterSetupPayload(
            vendorId: 0x0001,
            productId: 0x0001,
            discriminator: 1,
            passcode: 1
        )
        
        let qrCode = payload.generateQRCodePayload()
        
        // Should generate a valid QR code even with minimal values
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        XCTAssertGreaterThan(qrCode.count, 10) // Should have substantial content
    }
    
    func testMaximumValues() {
        let payload = MatterSetupPayload(
            vendorId: 0xFFFF,
            productId: 0xFFFF,
            discriminator: 0x0FFF, // 12-bit max
            passcode: 134217727 // 27-bit max (0x7FFFFFF)
        )
        
        let qrCode = payload.generateQRCodePayload()
        
        // Should handle maximum values without crashing
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        XCTAssertNotEqual(qrCode, "MT:")
    }
    
    // MARK: - CommissioningConfig Extension Tests
    
    func testCommissioningConfigQRGeneration() {
        let commissioning = CommissioningConfig(
            discriminator: 3840,
            passcode: 20202021
        )
        
        let qrCode = commissioning.generateQRCode(vendorId: 0xFFF1, productId: 0x8000)
        
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        XCTAssertGreaterThan(qrCode.count, 3)
    }
    
    func testCommissioningConfigManualCodeGeneration() throws {
        let commissioning = CommissioningConfig(
            discriminator: 3840,
            passcode: 20202021
        )
        
        let manualCode = try commissioning.generateManualPairingCode()
        
        XCTAssertTrue(manualCode.contains("-"))
        let parts = manualCode.split(separator: "-")
        XCTAssertEqual(parts.count, 2)
    }
    
    func testCreateSetupPayloadExtension() {
        let commissioning = CommissioningConfig(
            discriminator: 3840,
            passcode: 20202021
        )
        
        let payload = commissioning.createSetupPayload(vendorId: 0xFFF1, productId: 0x8000)
        
        XCTAssertEqual(payload.vendorId, 0xFFF1)
        XCTAssertEqual(payload.productId, 0x8000)
        XCTAssertEqual(payload.discriminator, 3840)
        XCTAssertEqual(payload.passcode, 20202021)
    }
    
    // MARK: - MatterConfig Extension Tests
    
    func testMatterConfigQRGeneration() {
        let commissioning = CommissioningConfig(
            discriminator: 3840,
            passcode: 20202021
        )
        
        let matterConfig = MatterConfig(
            enabled: true,
            deviceType: "temperature_sensor",
            vendorId: 0xFFF1,
            productId: 0x8000,
            commissioning: commissioning,
            thread: nil,
            network: nil
        )
        
        let qrCode = matterConfig.generateQRCode()
        
        XCTAssertNotNil(qrCode)
        XCTAssertTrue(qrCode!.hasPrefix("MT:"))
    }
    
    func testMatterConfigWithoutCommissioning() {
        let matterConfig = MatterConfig(
            enabled: true,
            deviceType: "temperature_sensor",
            vendorId: 0xFFF1,
            productId: 0x8000,
            commissioning: nil,
            thread: nil,
            network: nil
        )
        
        let qrCode = matterConfig.generateQRCode()
        let manualCode = matterConfig.generateManualPairingCode()
        
        XCTAssertNil(qrCode)
        XCTAssertNil(manualCode)
    }
    
    // MARK: - Edge Cases
    
    func testZeroDiscriminator() throws {
        let payload = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 0,
            passcode: 20202021
        )
        
        let qrCode = payload.generateQRCodePayload()
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        
        let manualCode = try payload.generateManualPairingCode()
        // Verify format is correct (5 digits, hyphen, 6 digits)
        XCTAssertTrue(manualCode.contains("-"), "Manual code should contain hyphen")
        let parts = manualCode.split(separator: "-")
        XCTAssertEqual(parts.count, 2, "Should have two parts")
        XCTAssertEqual(parts[0].count, 5, "First part should be 5 digits")
        XCTAssertEqual(parts[1].count, 6, "Second part should be 6 digits")
    }
    
    func testCustomVersionAndCapabilities() {
        let payload = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3840,
            passcode: 20202021,
            version: 1,
            commissioningFlow: 1,
            discoveryCapabilities: 0x07
        )
        
        let qrCode = payload.generateQRCodePayload()
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        
        // Different parameters should produce different QR code
        let standardPayload = MatterSetupPayload(
            vendorId: 0xFFF1,
            productId: 0x8000,
            discriminator: 3840,
            passcode: 20202021
        )
        
        let standardQR = standardPayload.generateQRCodePayload()
        XCTAssertNotEqual(qrCode, standardQR)
    }
    
}