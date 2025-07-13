import XCTest
@testable import CodeGeneration
@testable import ESPHomeSwiftCore
@testable import ComponentLibrary

final class CodeGenerationTests: XCTestCase {
    
    func testCodeGeneratorCreation() {
        let generator = CodeGenerator()
        XCTAssertNotNil(generator)
    }
    
    func testProjectBuilderCreation() {
        let builder = ProjectBuilder()
        XCTAssertNotNil(builder)
    }
    
    func testBasicCodeGeneration() throws {
        let config = ESPHomeConfiguration(
            esphomeSwift: CoreConfig(name: "test_device"),
            esp32: ESP32Config(
                board: "esp32-c6-devkitc-1",
                framework: FrameworkConfig(type: .espIDF)
            )
        )
        
        let generator = CodeGenerator()
        let result = try generator.generateCode(
            from: config,
            outputDirectory: "/tmp/test"
        )
        
        // Basic checks that content was generated
        XCTAssertFalse(result.mainCpp.isEmpty)
        XCTAssertFalse(result.cmakeLists.isEmpty)
        XCTAssertFalse(result.sdkConfig.isEmpty)
        
        // Check for expected content in generated files
        XCTAssertTrue(result.mainCpp.contains("ESPHome Swift"))
        XCTAssertTrue(result.cmakeLists.contains("cmake_minimum_required"))
    }
}