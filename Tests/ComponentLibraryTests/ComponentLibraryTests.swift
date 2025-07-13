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
        
        XCTAssertTrue(platforms.contains("dht"))
        XCTAssertTrue(platforms.contains("gpio"))
        XCTAssertTrue(platforms.contains("adc"))
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
}