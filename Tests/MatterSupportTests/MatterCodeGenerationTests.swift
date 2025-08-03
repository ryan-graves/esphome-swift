import XCTest
@testable import MatterSupport
@testable import ESPHomeSwiftCore

final class MatterCodeGenerationTests: XCTestCase {
    
    func testBasicMatterCodeGeneration() throws {
        let config = MatterConfig(
            deviceType: "on_off_light",
            vendorId: 0x1234,
            productId: 0x5678
        )
        
        let context = SwiftEmbeddedContext(
            board: "esp32-c6-devkitc-1",
            projectName: "test",
            dependencies: ["esp_matter", "nvs_flash", "app_update"]
        )
        
        let matterCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test Swift Embedded code generation
        XCTAssertFalse(matterCode.swiftCode.isEmpty)
        XCTAssertTrue(matterCode.swiftCode.contains("MatterDevice"))
        XCTAssertTrue(matterCode.swiftCode.contains("MatterManager"))
        XCTAssertTrue(matterCode.swiftCode.contains("import SwiftEmbeddedCore"))
        
        // Test C bridge code generation
        XCTAssertFalse(matterCode.cBridgeCode.isEmpty)
        XCTAssertTrue(matterCode.cBridgeCode.contains("kVendorId = 4660")) // 0x1234
        XCTAssertTrue(matterCode.cBridgeCode.contains("kProductId = 22136")) // 0x5678
        XCTAssertTrue(matterCode.cBridgeCode.contains("esp_matter::node::create"))
        XCTAssertTrue(matterCode.cBridgeCode.contains("esp_matter::start"))
        XCTAssertTrue(matterCode.cBridgeCode.contains("app_event_cb"))
        
        // Test CMake configuration
        XCTAssertFalse(matterCode.cmakeConfiguration.isEmpty)
        XCTAssertTrue(matterCode.cmakeConfiguration.contains("esp_matter"))
        XCTAssertTrue(matterCode.cmakeConfiguration.contains("CONFIG_ENABLE_MATTER"))
    }
    
    func testMatterCodeGenerationWithCommissioning() throws {
        let commissioning = CommissioningConfig(
            discriminator: 3840,
            passcode: 20202021
        )
        
        let config = MatterConfig(
            deviceType: "on_off_switch", 
            vendorId: 0xFFF1,
            productId: 0x8001,
            commissioning: commissioning
        )
        
        let context = SwiftEmbeddedContext(
            board: "esp32-c6-devkitc-1",
            projectName: "test",
            dependencies: ["esp_matter", "nvs_flash", "app_update"]
        )
        
        let matterCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test commissioning parameters in C bridge
        XCTAssertTrue(matterCode.cBridgeCode.contains("kDiscriminator = 3840"))
        XCTAssertTrue(matterCode.cBridgeCode.contains("kSetupPinCode = 20202021"))
        XCTAssertTrue(matterCode.cBridgeCode.contains("kVendorId = 65521")) // 0xFFF1
        XCTAssertTrue(matterCode.cBridgeCode.contains("kProductId = 32769")) // 0x8001
    }
    
    func testMatterDeviceTypeCompatibility() {
        // Test device type compatibility with Swift Embedded component types
        XCTAssertTrue(MatterDeviceType.onOffLight.isCompatible(with: .light))
        XCTAssertTrue(MatterDeviceType.temperatureSensor.isCompatible(with: .sensor))
        XCTAssertTrue(MatterDeviceType.onOffSwitch.isCompatible(with: .`switch`))
        XCTAssertTrue(MatterDeviceType.contactSensor.isCompatible(with: .binarySensor))
        
        // Test incompatible combinations
        XCTAssertFalse(MatterDeviceType.onOffLight.isCompatible(with: .sensor))
        XCTAssertFalse(MatterDeviceType.temperatureSensor.isCompatible(with: .`switch`))
    }
    
    func testMatterDeviceTypeIds() {
        // Test key Matter device type IDs
        XCTAssertEqual(MatterDeviceType.onOffLight.deviceTypeId, 0x0100)
        XCTAssertEqual(MatterDeviceType.temperatureSensor.deviceTypeId, 0x0302)
        XCTAssertEqual(MatterDeviceType.onOffSwitch.deviceTypeId, 0x0103)
        XCTAssertEqual(MatterDeviceType.contactSensor.deviceTypeId, 0x0015)
    }
    
    func testSwiftEmbeddedComponentTypes() {
        // Test Swift Embedded component type definitions
        XCTAssertEqual(SwiftEmbeddedComponentType.sensor.rawValue, "sensor")
        XCTAssertEqual(SwiftEmbeddedComponentType.`switch`.rawValue, "switch")
        XCTAssertEqual(SwiftEmbeddedComponentType.light.rawValue, "light")
        XCTAssertEqual(SwiftEmbeddedComponentType.binarySensor.rawValue, "binary_sensor")
        
        // Test all cases are covered
        XCTAssertEqual(SwiftEmbeddedComponentType.allCases.count, 7)
    }
}