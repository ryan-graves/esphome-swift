import XCTest
@testable import MatterSupport
@testable import ESPHomeSwiftCore

final class MatterConfigurationTests: XCTestCase {
    
    func testMatterConfigDefaults() {
        let config = MatterConfig(
            deviceType: "on_off_light"
        )
        
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.deviceType, "on_off_light")
        XCTAssertEqual(config.vendorId, 0xFFF1)
        XCTAssertEqual(config.productId, 0x8000)
        XCTAssertNil(config.commissioning)
        XCTAssertNil(config.thread)
        XCTAssertNil(config.network)
    }
    
    func testMatterConfigDeviceTypeConversion() {
        let config = MatterConfig(deviceType: "on_off_light")
        
        XCTAssertNotNil(config.matterDeviceType)
        XCTAssertEqual(config.matterDeviceType, .onOffLight)
        
        let invalidConfig = MatterConfig(deviceType: "invalid_device_type")
        XCTAssertNil(invalidConfig.matterDeviceType)
    }
    
    func testMatterConfigTransportConversion() {
        let wifiConfig = MatterConfig(
            deviceType: "on_off_light",
            network: MatterNetworkConfig(transport: "wifi")
        )
        XCTAssertEqual(wifiConfig.matterTransport, .wifi)
        
        let threadConfig = MatterConfig(
            deviceType: "on_off_light",
            network: MatterNetworkConfig(transport: "thread")
        )
        XCTAssertEqual(threadConfig.matterTransport, .thread)
        
        let noNetworkConfig = MatterConfig(deviceType: "on_off_light")
        XCTAssertEqual(noNetworkConfig.matterTransport, .wifi) // Default
    }
    
    func testCommissioningConfigDefaults() {
        let config = CommissioningConfig()
        
        XCTAssertEqual(config.discriminator, 3840)
        XCTAssertEqual(config.passcode, 20202021)
        XCTAssertNil(config.manualPairingCode)
        XCTAssertNil(config.qrCodePayload)
    }
    
    func testCommissioningConfigCustomValues() {
        let config = CommissioningConfig(
            discriminator: 1234,
            passcode: 87654321,
            manualPairingCode: "12345-67890",
            qrCodePayload: "MT:TEST123"
        )
        
        XCTAssertEqual(config.discriminator, 1234)
        XCTAssertEqual(config.passcode, 87654321)
        XCTAssertEqual(config.manualPairingCode, "12345-67890")
        XCTAssertEqual(config.qrCodePayload, "MT:TEST123")
    }
    
    func testThreadConfigDefaults() {
        let config = ThreadConfig()
        
        XCTAssertTrue(config.enabled)
        XCTAssertNil(config.dataset)
        XCTAssertNil(config.networkName)
        XCTAssertNil(config.extPanId)
        XCTAssertNil(config.networkKey)
        XCTAssertNil(config.channel)
        XCTAssertNil(config.panId)
    }
    
    func testThreadConfigFromDataset() {
        let dataset = "0e080000000000000001000035060004001fffe0020811111111222222220708fd00"
        let config = ThreadConfig.fromDataset(dataset)
        
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.dataset, dataset)
    }
    
    func testThreadConfigCreate() {
        let config = ThreadConfig.create(
            networkName: "Test Network",
            networkKey: "11111111222222223333333344444444",
            channel: 15,
            panId: 0x1234,
            extPanId: "1111111122222222"
        )
        
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.networkName, "Test Network")
        XCTAssertEqual(config.networkKey, "11111111222222223333333344444444")
        XCTAssertEqual(config.channel, 15)
        XCTAssertEqual(config.panId, 0x1234)
        XCTAssertEqual(config.extPanId, "1111111122222222")
    }
    
    func testMatterNetworkConfigDefaults() {
        let config = MatterNetworkConfig()
        
        XCTAssertEqual(config.transport, "wifi")
        XCTAssertTrue(config.ipv6Enabled)
        XCTAssertNil(config.mdns)
    }
    
    func testMDNSConfigDefaults() {
        let config = MDNSConfig()
        
        XCTAssertTrue(config.enabled)
        XCTAssertNil(config.hostname)
        XCTAssertNil(config.services)
    }
    
    func testMatterConfigCreateWithDeviceType() {
        let config = MatterConfig.create(
            deviceType: .temperatureSensor,
            enabled: true,
            vendorId: 0x1234,
            productId: 0x5678
        )
        
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.deviceType, "temperature_sensor")
        XCTAssertEqual(config.vendorId, 0x1234)
        XCTAssertEqual(config.productId, 0x5678)
        XCTAssertEqual(config.matterDeviceType, .temperatureSensor)
    }
    
    func testCommissioningConfigCodeGeneration() {
        let config = CommissioningConfig()
        
        // Test QR code generation with default values
        let qrCode = config.generateQRCode()
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        XCTAssertGreaterThan(qrCode.count, 3)
        
        // Test manual pairing code generation with default values
        let manualCode = config.generateManualPairingCode()
        XCTAssertTrue(manualCode.contains("-"))
    }
    
    func testCommissioningConfigWithGeneratedCodes() {
        let baseConfig = CommissioningConfig(
            discriminator: 1111,
            passcode: 12345678
        )
        
        // Test generating QR code
        let qrCode = baseConfig.generateQRCode(vendorId: 0xFFF1, productId: 0x8000)
        XCTAssertTrue(qrCode.hasPrefix("MT:"))
        XCTAssertGreaterThan(qrCode.count, 3)
        
        // Test generating manual pairing code
        let manualCode = baseConfig.generateManualPairingCode(vendorId: 0xFFF1, productId: 0x8000)
        XCTAssertTrue(manualCode.contains("-"))
        
        // Test that codes are different from defaults
        let defaultConfig = CommissioningConfig()
        let defaultQR = defaultConfig.generateQRCode(vendorId: 0xFFF1, productId: 0x8000)
        XCTAssertNotEqual(qrCode, defaultQR)
    }
}