import XCTest
@testable import ComponentLibrary
@testable import ESPHomeSwiftCore

final class ComponentLibraryTests: XCTestCase {
    
    func testComponentRegistrySharedInstance() {
        let registry = ComponentRegistry.shared
        XCTAssertNotNil(registry)
    }
    
    func testAvailablePlatforms() {
        let registry = ComponentRegistry.shared
        let platforms = registry.availablePlatforms
        
        // Available component platforms
        XCTAssertTrue(platforms.contains("dht"))
        XCTAssertTrue(platforms.contains("adc"))
        XCTAssertTrue(platforms.contains("gpio"))
        XCTAssertTrue(platforms.contains("binary"))
        XCTAssertTrue(platforms.contains("rgb"))
    }
    
    func testDHTSensorFactory() throws {
        let factory = DHTSensorFactory()
        
        XCTAssertEqual(factory.platform, "dht")
        XCTAssertEqual(factory.componentType, .sensor)
        XCTAssertTrue(factory.requiredProperties.contains("pin"))
        XCTAssertTrue(factory.requiredProperties.contains("model"))
    }
    
    func testGPIOSensorFactory() throws {
        let factory = GPIOSensorFactory()
        
        XCTAssertEqual(factory.platform, "adc")
        XCTAssertEqual(factory.componentType, .sensor)
        XCTAssertTrue(factory.requiredProperties.contains("pin"))
    }
    
    func testGPIOSwitchFactory() throws {
        let factory = GPIOSwitchFactory()
        
        XCTAssertEqual(factory.platform, "gpio")
        XCTAssertEqual(factory.componentType, .`switch`)
        XCTAssertTrue(factory.requiredProperties.contains("pin"))
    }
    
    func testBinaryLightFactory() throws {
        let factory = BinaryLightFactory()
        
        XCTAssertEqual(factory.platform, "binary")
        XCTAssertEqual(factory.componentType, .light)
        XCTAssertTrue(factory.requiredProperties.contains("pin"))
    }
    
    func testRGBLightFactory() throws {
        let factory = RGBLightFactory()
        
        XCTAssertEqual(factory.platform, "rgb")
        XCTAssertEqual(factory.componentType, .light)
        XCTAssertTrue(factory.requiredProperties.contains("red_pin"))
        XCTAssertTrue(factory.requiredProperties.contains("green_pin"))
        XCTAssertTrue(factory.requiredProperties.contains("blue_pin"))
    }
    
    func testGPIOBinarySensorFactory() throws {
        let factory = GPIOBinarySensorFactory()
        
        XCTAssertEqual(factory.platform, "gpio")
        XCTAssertEqual(factory.componentType, .binarySensor)
        XCTAssertTrue(factory.requiredProperties.contains("pin"))
    }
    
    // MARK: - Board-Aware Validation Tests
    
    func testGPIOSwitchBoardAwareValidation() throws {
        let factory = GPIOSwitchFactory()
        
        // Test valid pin for ESP32-C6
        let validConfig = SwitchConfig(
            platform: "gpio",
            id: "test_switch",
            name: "test_switch",
            pin: PinConfig(number: .integer(5)),
            inverted: false,
            restoreMode: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: validConfig, board: "esp32-c6-devkitc-1"))
        
        // Test invalid pin for ESP32-C6 (input-only pin used for output)
        let invalidConfig = SwitchConfig(
            platform: "gpio",
            id: "test_switch",
            name: "test_switch",
            pin: PinConfig(number: .integer(18)),
            inverted: false,
            restoreMode: nil
        )
        
        XCTAssertThrowsError(try factory.validate(config: invalidConfig, board: "esp32-c6-devkitc-1"))
        
        // Test unsupported board
        XCTAssertThrowsError(try factory.validate(config: validConfig, board: "unsupported-board"))
    }
    
    func testGPIOSensorBoardAwareValidation() throws {
        let factory = GPIOSensorFactory()
        
        // Test valid ADC pin for ESP32-C6
        let validConfig = SensorConfig(
            platform: "adc",
            id: "test_sensor",
            name: "test_sensor",
            pin: PinConfig(number: .integer(3)),
            updateInterval: "60s",
            accuracy: nil,
            filters: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: validConfig, board: "esp32-c6-devkitc-1"))
        
        // Test invalid ADC pin for ESP32-C6 (beyond ADC range)
        let invalidConfig = SensorConfig(
            platform: "adc",
            id: "test_sensor",
            name: "test_sensor",
            pin: PinConfig(number: .integer(10)),
            updateInterval: "60s",
            accuracy: nil,
            filters: nil
        )
        
        XCTAssertThrowsError(try factory.validate(config: invalidConfig, board: "esp32-c6-devkitc-1"))
        
        // Test valid ADC pin for ESP32-C3 (different range)
        let c3ValidConfig = SensorConfig(
            platform: "adc",
            id: "test_sensor",
            name: "test_sensor",
            pin: PinConfig(number: .integer(2)),
            updateInterval: "60s",
            accuracy: nil,
            filters: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: c3ValidConfig, board: "esp32-c3-devkitm-1"))
        
        // Test invalid ADC pin for ESP32-C3 (beyond C3 ADC range)
        let c3InvalidConfig = SensorConfig(
            platform: "adc",
            id: "test_sensor",
            name: "test_sensor",
            pin: PinConfig(number: .integer(7)),
            updateInterval: "60s",
            accuracy: nil,
            filters: nil
        )
        
        XCTAssertThrowsError(try factory.validate(config: c3InvalidConfig, board: "esp32-c3-devkitm-1"))
    }
    
    func testRGBLightBoardAwareValidation() throws {
        let factory = RGBLightFactory()
        
        // Test valid PWM pins for ESP32-C6
        let validConfig = LightConfig(
            platform: "rgb",
            id: "test_rgb",
            name: "test_rgb",
            pin: nil,
            redPin: PinConfig(number: .integer(6)),
            greenPin: PinConfig(number: .integer(7)),
            bluePin: PinConfig(number: .integer(8)),
            whitePin: nil,
            effects: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: validConfig, board: "esp32-c6-devkitc-1"))
        
        // Test invalid PWM pin for ESP32-C6 (input-only pin)
        let invalidConfig = LightConfig(
            platform: "rgb",
            id: "test_rgb",
            name: "test_rgb",
            pin: nil,
            redPin: PinConfig(number: .integer(18)),
            greenPin: PinConfig(number: .integer(7)),
            bluePin: PinConfig(number: .integer(8)),
            whitePin: nil,
            effects: nil
        )
        
        XCTAssertThrowsError(try factory.validate(config: invalidConfig, board: "esp32-c6-devkitc-1"))
    }
    
    func testDHTSensorBoardAwareValidation() throws {
        let factory = DHTSensorFactory()
        
        // Test valid GPIO pin for ESP32-C6
        let validConfig = SensorConfig(
            platform: "dht",
            id: "test_dht",
            name: "test_dht",
            pin: PinConfig(number: .integer(4)),
            updateInterval: "60s",
            accuracy: nil,
            filters: nil,
            model: .dht22
        )
        
        XCTAssertNoThrow(try factory.validate(config: validConfig, board: "esp32-c6-devkitc-1"))
        
        // Test pin availability across different boards
        let esp32H2Config = SensorConfig(
            platform: "dht",
            id: "test_dht",
            name: "test_dht",
            pin: PinConfig(number: .integer(25)),
            updateInterval: "60s",
            accuracy: nil,
            filters: nil,
            model: .dht22
        )
        
        // Should work on ESP32-H2 (has GPIO25)
        XCTAssertNoThrow(try factory.validate(config: esp32H2Config, board: "esp32-h2-devkitc-1"))
        
        // Should fail on ESP32-C3 (no GPIO25)
        XCTAssertThrowsError(try factory.validate(config: esp32H2Config, board: "esp32-c3-devkitm-1"))
    }
    
    func testBinaryLightBoardAwareValidation() throws {
        let factory = BinaryLightFactory()
        
        // Test valid output pin for ESP32-C6
        let validConfig = LightConfig(
            platform: "binary",
            id: "test_binary",
            name: "test_binary",
            pin: PinConfig(number: .integer(2)),
            redPin: nil,
            greenPin: nil,
            bluePin: nil,
            whitePin: nil,
            effects: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: validConfig, board: "esp32-c6-devkitc-1"))
        
        // Test invalid output pin for ESP32-C6 (input-only pin)
        let invalidConfig = LightConfig(
            platform: "binary",
            id: "test_binary",
            name: "test_binary",
            pin: PinConfig(number: .integer(19)),
            redPin: nil,
            greenPin: nil,
            bluePin: nil,
            whitePin: nil,
            effects: nil
        )
        
        XCTAssertThrowsError(try factory.validate(config: invalidConfig, board: "esp32-c6-devkitc-1"))
    }
    
    func testGPIOBinarySensorBoardAwareValidation() throws {
        let factory = GPIOBinarySensorFactory()
        
        // Test valid input pin for ESP32-C6
        let validConfig = BinarySensorConfig(
            platform: "gpio",
            id: "test_binary_sensor",
            name: "test_binary_sensor",
            pin: PinConfig(number: .integer(3)),
            deviceClass: nil,
            inverted: nil,
            filters: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: validConfig, board: "esp32-c6-devkitc-1"))
        
        // Test input-only pin (should work for input)
        let inputOnlyConfig = BinarySensorConfig(
            platform: "gpio",
            id: "test_binary_sensor",
            name: "test_binary_sensor",
            pin: PinConfig(number: .integer(18)),
            deviceClass: nil,
            inverted: nil,
            filters: nil
        )
        
        XCTAssertNoThrow(try factory.validate(config: inputOnlyConfig, board: "esp32-c6-devkitc-1"))
        
        // Test pin not available on board
        let unavailableConfig = BinarySensorConfig(
            platform: "gpio",
            id: "test_binary_sensor",
            name: "test_binary_sensor",
            pin: PinConfig(number: .integer(50)),
            deviceClass: nil,
            inverted: nil,
            filters: nil
        )
        
        XCTAssertThrowsError(try factory.validate(config: unavailableConfig, board: "esp32-c6-devkitc-1"))
    }
}