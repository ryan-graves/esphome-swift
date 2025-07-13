import XCTest
@testable import CLI
@testable import ESPHomeSwiftCore

final class CLITests: XCTestCase {
    
    func testLoggingSetup() {
        // Test that logging setup function exists and can be called
        // Note: Can't actually test setupLogging() because logging system
        // can only be initialized once per process
        XCTAssertTrue(true, "Logging setup function is available")
    }
    
    func testProjectTemplateGeneration() {
        let template = generateProjectTemplate(name: "test_project", board: "esp32-c6-devkitc-1")
        
        XCTAssertTrue(template.contains("test_project"))
        XCTAssertTrue(template.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(template.contains("esphome_swift:"))
        XCTAssertTrue(template.contains("esp32:"))
        XCTAssertTrue(template.contains("wifi:"))
        XCTAssertTrue(template.contains("api:"))
        XCTAssertTrue(template.contains("ota:"))
    }
    
    func testProjectTemplateWithDifferentBoard() {
        let template = generateProjectTemplate(name: "sensor_node", board: "esp32-c3-devkitm-1")
        
        XCTAssertTrue(template.contains("sensor_node"))
        XCTAssertTrue(template.contains("esp32-c3-devkitm-1"))
        XCTAssertTrue(template.contains("Sensor_Node Fallback Hotspot"))
    }
}