import XCTest
@testable import ESPHomeSwiftCore

final class ConfigurationTests: XCTestCase {
    
    func testBasicConfigurationParsing() throws {
        let yaml = """
        esphome_swift:
          name: test_device
          friendly_name: "Test Device"
        
        esp32:
          board: esp32-c6-devkitc-1
          framework:
            type: swift-embedded
        
        wifi:
          ssid: "TestNetwork"
          password: "TestPassword"
        
        api:
          encryption:
            key: "test_encryption_key"
        
        logger:
          level: INFO
        """
        
        let parser = ConfigurationParser()
        let config = try parser.parse(yaml: yaml)
        
        XCTAssertEqual(config.esphomeSwift.name, "test_device")
        XCTAssertEqual(config.esphomeSwift.friendlyName, "Test Device")
        XCTAssertEqual(config.esp32.board, "esp32-c6-devkitc-1")
        XCTAssertEqual(config.esp32.framework.type, .swiftEmbedded)
        XCTAssertEqual(config.wifi?.ssid, "TestNetwork")
        XCTAssertEqual(config.wifi?.password, "TestPassword")
        XCTAssertEqual(config.api?.encryption?.key, "test_encryption_key")
        XCTAssertEqual(config.logger?.level, .info)
    }
    
    func testSensorConfiguration() throws {
        let yaml = """
        esphome_swift:
          name: sensor_test
        
        esp32:
          board: esp32-c6-devkitc-1
          framework:
            type: swift-embedded
        
        sensor:
          - platform: dht
            pin:
              number: GPIO4
            model: DHT22
            temperature:
              name: "Living Room Temperature"
            humidity:
              name: "Living Room Humidity"
            update_interval: 60s
          - platform: adc
            pin:
              number: GPIO1
            name: "Battery Voltage"
        """
        
        let parser = ConfigurationParser()
        let config = try parser.parse(yaml: yaml)
        
        XCTAssertEqual(config.sensor?.count, 2)
        
        let dhtSensor = config.sensor?[0]
        XCTAssertEqual(dhtSensor?.platform, "dht")
        XCTAssertEqual(dhtSensor?.model, .dht22)
        XCTAssertEqual(dhtSensor?.temperature?.name, "Living Room Temperature")
        XCTAssertEqual(dhtSensor?.humidity?.name, "Living Room Humidity")
        
        let adcSensor = config.sensor?[1]
        XCTAssertEqual(adcSensor?.platform, "adc")
        XCTAssertEqual(adcSensor?.name, "Battery Voltage")
    }
    
    func testSwitchConfiguration() throws {
        let yaml = """
        esphome_swift:
          name: switch_test
        
        esp32:
          board: esp32-c6-devkitc-1
          framework:
            type: swift-embedded
        
        switch:
          - platform: gpio
            pin:
              number: GPIO5
            name: "Relay 1"
            inverted: false
          - platform: gpio
            pin:
              number: GPIO6
            name: "Relay 2"
            inverted: true
            restore_mode: ALWAYS_ON
        """
        
        let parser = ConfigurationParser()
        let config = try parser.parse(yaml: yaml)
        
        XCTAssertEqual(config.`switch`?.count, 2)
        
        let switch1 = config.`switch`?[0]
        XCTAssertEqual(switch1?.platform, "gpio")
        XCTAssertEqual(switch1?.name, "Relay 1")
        XCTAssertEqual(switch1?.inverted, false)
        
        let switch2 = config.`switch`?[1]
        XCTAssertEqual(switch2?.platform, "gpio")
        XCTAssertEqual(switch2?.name, "Relay 2")
        XCTAssertEqual(switch2?.inverted, true)
        XCTAssertEqual(switch2?.restoreMode, .alwaysOn)
    }
    
    func testValidationErrors() {
        let invalidYaml = """
        esphome_swift:
          name: "invalid-name-with-dashes"
        
        esp32:
          board: esp32-c6-devkitc-1
          framework:
            type: swift-embedded
        """
        
        let parser = ConfigurationParser()
        
        XCTAssertThrowsError(try parser.parse(yaml: invalidYaml)) { error in
            if let validationError = error as? ValidationError {
                switch validationError {
                case .invalidNodeName:
                    // Expected error
                    break
                default:
                    XCTFail("Unexpected validation error: \\(validationError)")
                }
            } else {
                XCTFail("Expected ValidationError, got: \\(error)")
            }
        }
    }
    
    func testPinConfiguration() throws {
        let yaml = """
        esphome_swift:
          name: pin_test
        
        esp32:
          board: esp32-c6-devkitc-1
          framework:
            type: swift-embedded
        
        switch:
          - platform: gpio
            pin: 
              number: GPIO5
              mode: OUTPUT
              inverted: false
            name: "Test Switch"
        """
        
        let parser = ConfigurationParser()
        let config = try parser.parse(yaml: yaml)
        
        let switchConfig = config.`switch`?[0]
        
        if case .gpio(let gpioString) = switchConfig?.pin?.number {
            XCTAssertEqual(gpioString, "GPIO5")
        } else {
            XCTFail("Expected GPIO string pin number")
        }
        
        XCTAssertEqual(switchConfig?.pin?.mode, .output)
        XCTAssertEqual(switchConfig?.pin?.inverted, false)
    }
}