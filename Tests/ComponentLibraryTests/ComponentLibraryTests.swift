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
        
        // Converted factories
        XCTAssertTrue(platforms.contains("dht"))
        XCTAssertTrue(platforms.contains("adc"))
        XCTAssertTrue(platforms.contains("gpio"))
        XCTAssertTrue(platforms.contains("binary"))
        XCTAssertTrue(platforms.contains("rgb"))
        XCTAssertTrue(platforms.contains("gpio_binary"))
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
        XCTAssertEqual(factory.componentType, .switch_)
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
        
        XCTAssertEqual(factory.platform, "gpio_binary")
        XCTAssertEqual(factory.componentType, .binarySensor)
        XCTAssertTrue(factory.requiredProperties.contains("pin"))
    }
}