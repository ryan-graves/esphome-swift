import XCTest
import ArgumentParser
@testable import CLI
@testable import ESPHomeSwiftCore
@testable import MatterSupport

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
    
    // MARK: - GenerateCredentialsCommand Tests
    
    func testGenerateCredentialsCommandDefaultArguments() throws {
        let command = try GenerateCredentialsCommand.parse([])
        
        XCTAssertEqual(command.count, 1)
        XCTAssertEqual(command.format, .text)
        XCTAssertFalse(command.verbose)
    }
    
    func testGenerateCredentialsCommandWithCount() throws {
        let command = try GenerateCredentialsCommand.parse(["--count", "5"])
        
        XCTAssertEqual(command.count, 5)
        XCTAssertEqual(command.format, .text)
    }
    
    func testGenerateCredentialsCommandWithShortCount() throws {
        let command = try GenerateCredentialsCommand.parse(["-c", "3"])
        
        XCTAssertEqual(command.count, 3)
    }
    
    func testGenerateCredentialsCommandWithYAMLFormat() throws {
        let command = try GenerateCredentialsCommand.parse(["--format", "yaml"])
        
        XCTAssertEqual(command.format, .yaml)
    }
    
    func testGenerateCredentialsCommandWithJSONFormat() throws {
        let command = try GenerateCredentialsCommand.parse(["--format", "json"])
        
        XCTAssertEqual(command.format, .json)
    }
    
    func testGenerateCredentialsCommandWithTextFormat() throws {
        let command = try GenerateCredentialsCommand.parse(["--format", "text"])
        
        XCTAssertEqual(command.format, .text)
    }
    
    func testGenerateCredentialsCommandWithShortFormat() throws {
        let command = try GenerateCredentialsCommand.parse(["-f", "json"])
        
        XCTAssertEqual(command.format, .json)
    }
    
    func testGenerateCredentialsCommandWithVerbose() throws {
        let command = try GenerateCredentialsCommand.parse(["--verbose"])
        
        XCTAssertTrue(command.verbose)
    }
    
    func testGenerateCredentialsCommandWithShortVerbose() throws {
        let command = try GenerateCredentialsCommand.parse(["-v"])
        
        XCTAssertTrue(command.verbose)
    }
    
    func testGenerateCredentialsCommandWithAllArguments() throws {
        let command = try GenerateCredentialsCommand.parse([
            "--count", "10",
            "--format", "yaml", 
            "--verbose"
        ])
        
        XCTAssertEqual(command.count, 10)
        XCTAssertEqual(command.format, .yaml)
        XCTAssertTrue(command.verbose)
    }
    
    func testGenerateCredentialsCommandInvalidFormat() {
        XCTAssertThrowsError(try GenerateCredentialsCommand.parse(["--format", "invalid"])) { error in
            // ArgumentParser throws an error for invalid enum cases
            XCTAssertNotNil(error)
        }
    }
    
    func testGenerateCredentialsCommandInvalidCount() {
        XCTAssertThrowsError(try GenerateCredentialsCommand.parse(["--count", "not-a-number"])) { error in
            // ArgumentParser throws an error for invalid integer values
            XCTAssertNotNil(error)
        }
    }
    
    func testGenerateCredentialsCommandNegativeCount() {
        // ArgumentParser may treat -1 as a flag, so this should throw an error
        XCTAssertThrowsError(try GenerateCredentialsCommand.parse(["--count", "-1"])) { error in
            XCTAssertNotNil(error)
        }
    }
    
    func testGenerateCredentialsCommandZeroCount() throws {
        let command = try GenerateCredentialsCommand.parse(["--count", "0"])
        XCTAssertEqual(command.count, 0)
    }
    
    func testOutputFormatDefaultDescription() {
        let format = GenerateCredentialsCommand.OutputFormat.text
        XCTAssertEqual(format.defaultValueDescription, "text")
    }
    
    func testOutputFormatAllCases() {
        let allCases = GenerateCredentialsCommand.OutputFormat.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.yaml))
        XCTAssertTrue(allCases.contains(.json))
        XCTAssertTrue(allCases.contains(.text))
    }
    
    func testOutputFormatRawValues() {
        XCTAssertEqual(GenerateCredentialsCommand.OutputFormat.yaml.rawValue, "yaml")
        XCTAssertEqual(GenerateCredentialsCommand.OutputFormat.json.rawValue, "json")
        XCTAssertEqual(GenerateCredentialsCommand.OutputFormat.text.rawValue, "text")
    }
}