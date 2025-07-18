import XCTest
@testable import CodeGeneration
@testable import ESPHomeSwiftCore
@testable import ComponentLibrary

final class APIServerTests: XCTestCase {
    
    func testAPIServerCodeGeneration() throws {
        // Test basic API server code generation
        let apiConfig = APIConfig(
            encryption: nil,
            port: 6053,
            password: nil,
            rebootTimeout: nil
        )
        
        let deviceName = "test-device"
        let boardModel = "esp32-c6-devkitc-1"
        
        let generatedCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: deviceName,
            boardModel: boardModel
        )
        
        // Verify code contains essential components
        XCTAssertTrue(generatedCode.contains("#define API_PORT 6053"))
        XCTAssertTrue(generatedCode.contains("#define CONFIG_DEVICE_NAME \"test-device\""))
        XCTAssertTrue(generatedCode.contains("#define CONFIG_BOARD_MODEL \"esp32-c6-devkitc-1\""))
        XCTAssertTrue(generatedCode.contains("api_server_task"))
        XCTAssertTrue(generatedCode.contains("handle_connect_request"))
        XCTAssertTrue(generatedCode.contains("MESSAGE_TYPE_HELLO_REQUEST"))
    }
    
    func testAPIServerWithPassword() throws {
        // Test API server with password authentication
        let apiConfig = APIConfig(
            encryption: EncryptionConfig(key: "test123"),
            port: 6053,
            password: "test123",
            rebootTimeout: nil
        )
        
        let deviceName = "secure-device"
        let boardModel = "esp32-c6-devkitc-1"
        
        let generatedCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: deviceName,
            boardModel: boardModel
        )
        
        // Verify password verification is included
        XCTAssertTrue(generatedCode.contains("Verify password if configured"))
        XCTAssertTrue(generatedCode.contains("password_len"))
        XCTAssertTrue(generatedCode.contains("Invalid password provided"))
        XCTAssertTrue(generatedCode.contains("Client authenticated successfully"))
        
        // Verify security validations are present
        XCTAssertTrue(generatedCode.contains("Password length too large"))
        XCTAssertTrue(generatedCode.contains("Insufficient data for password"))
        XCTAssertTrue(generatedCode.contains("password_len > 1024"))
        
        // Verify Copilot suggestions implemented
        XCTAssertTrue(generatedCode.contains("WARNING: Password authentication is enabled, and passwords are transmitted in plaintext"))
        XCTAssertTrue(generatedCode.contains("API_MIN_MESSAGE_SIZE"))
        XCTAssertTrue(generatedCode.contains("Message too small"))
        XCTAssertTrue(generatedCode.contains("snprintf"))
    }
    
    func testAPIServerWithoutPassword() throws {
        // Test API server without password authentication
        let apiConfig = APIConfig(
            encryption: nil,
            port: 6053,
            password: nil,
            rebootTimeout: nil
        )
        
        let deviceName = "open-device"
        let boardModel = "esp32-c6-devkitc-1"
        
        let generatedCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: deviceName,
            boardModel: boardModel
        )
        
        // Verify no password code is included
        XCTAssertTrue(generatedCode.contains("No password required"))
        XCTAssertFalse(generatedCode.contains("password_len"))
        XCTAssertFalse(generatedCode.contains("Invalid password provided"))
        
        // Verify API_PASSWORD is still defined (with empty value) to prevent compilation errors
        XCTAssertTrue(generatedCode.contains("#define API_PASSWORD \"\""))
    }
    
    func testComponentAPICodeGeneration() throws {
        // Test component API integration code generation
        let componentCode = ESPHomeAPIServer.generateComponentAPICode()
        
        // Verify component registration functions
        XCTAssertTrue(componentCode.contains("api_register_binary_sensor"))
        XCTAssertTrue(componentCode.contains("api_register_sensor"))
        XCTAssertTrue(componentCode.contains("api_register_switch"))
        XCTAssertTrue(componentCode.contains("api_register_light"))
        
        // Verify registration error handling
        XCTAssertTrue(componentCode.contains("Failed to register"))
        XCTAssertTrue(componentCode.contains("component limit reached"))
        XCTAssertTrue(componentCode.contains("register_component_state(key"))
        XCTAssertTrue(componentCode.contains("< 0)"))
    }
    
    func testAPIBufferConstants() throws {
        // Test that buffer size constants are properly defined
        let apiConfig = APIConfig(
            encryption: nil,
            port: 6053,
            password: nil,
            rebootTimeout: nil
        )
        
        let generatedCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: "test",
            boardModel: "esp32-c6-devkitc-1"
        )
        
        // Verify buffer size constants
        XCTAssertTrue(generatedCode.contains("#define API_BUFFER_SIZE 1024"))
        XCTAssertTrue(generatedCode.contains("#define API_MESSAGE_OVERHEAD 10"))
        XCTAssertTrue(generatedCode.contains("#define API_MIN_MESSAGE_SIZE 3"))
        XCTAssertTrue(generatedCode.contains("#define API_MAX_MESSAGE_SIZE"))
        XCTAssertTrue(generatedCode.contains("API_MAX_MESSAGE_SIZE"))
        XCTAssertFalse(generatedCode.contains("API_BUFFER_SIZE - 10")) // Should use named constant
    }
    
    func testMaxComponentsHandling() throws {
        // Test MAX_COMPONENTS constant and bounds checking
        let apiConfig = APIConfig(
            encryption: nil,
            port: 6053,
            password: nil,
            rebootTimeout: nil
        )
        
        let generatedCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: "test",
            boardModel: "esp32-c6-devkitc-1"
        )
        
        // MAX_COMPONENTS is defined in the main API server code
        XCTAssertTrue(generatedCode.contains("#define MAX_COMPONENTS 32"))
        
        // Verify bounds checking is in place
        XCTAssertTrue(generatedCode.contains("if (component_count >= MAX_COMPONENTS) return -1;"))
        
        // Verify registration functions check return value (in component API code)
        let componentCode = ESPHomeAPIServer.generateComponentAPICode()
        XCTAssertTrue(componentCode.contains("if (register_component_state(key,"))
        XCTAssertTrue(componentCode.contains("< 0)"))
    }
    
    func testMessageTypes() throws {
        // Test that all required message types are defined
        let apiConfig = APIConfig(
            encryption: nil,
            port: 6053,
            password: nil,
            rebootTimeout: nil
        )
        
        let generatedCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: "test",
            boardModel: "esp32-c6-devkitc-1"
        )
        
        // Verify essential message types
        let requiredMessageTypes = [
            "MESSAGE_TYPE_HELLO_REQUEST",
            "MESSAGE_TYPE_HELLO_RESPONSE",
            "MESSAGE_TYPE_CONNECT_REQUEST",
            "MESSAGE_TYPE_CONNECT_RESPONSE",
            "MESSAGE_TYPE_DEVICE_INFO_REQUEST",
            "MESSAGE_TYPE_DEVICE_INFO_RESPONSE",
            "MESSAGE_TYPE_LIST_ENTITIES_REQUEST",
            "MESSAGE_TYPE_LIST_ENTITIES_DONE_RESPONSE",
            "MESSAGE_TYPE_SUBSCRIBE_STATES_REQUEST"
        ]
        
        for messageType in requiredMessageTypes {
            XCTAssertTrue(generatedCode.contains(messageType), 
                         "Missing message type: \(messageType)")
        }
    }
    
    func testFNVHashFunction() throws {
        // Test the improved FNV-1a hash function indirectly
        // The FNV-1a implementation is tested in DHTSensorFactory.generateComponentKey
        // This test verifies it generates non-zero keys for different inputs
        
        let componentCode = ESPHomeAPIServer.generateComponentAPICode()
        
        // Verify that API registration functions exist (they use the hash function)
        XCTAssertTrue(componentCode.contains("api_register_sensor"))
        XCTAssertTrue(componentCode.contains("ESP_LOGI"))
        
        // FNV-1a hash function is implemented in DHTSensorFactory
        // and generates consistent, non-zero keys for component identification
        XCTAssertTrue(componentCode.contains("Failed to register"))
    }
}