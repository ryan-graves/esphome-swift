import XCTest
@testable import MatterSupport
@testable import ESPHomeSwiftCore
@testable import ComponentLibrary

final class MatterCodeGenerationTests: XCTestCase {
    
    func testBasicMatterCodeGeneration() throws {
        let config = MatterConfig(
            deviceType: "on_off_light",
            vendorId: 0x1234,
            productId: 0x5678
        )
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        let componentCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test header includes
        XCTAssertFalse(componentCode.headerIncludes.isEmpty)
        XCTAssertTrue(componentCode.headerIncludes.contains("#include \"esp_matter.h\""))
        XCTAssertTrue(componentCode.headerIncludes.contains("#include \"esp_log.h\""))
        XCTAssertTrue(componentCode.headerIncludes.contains("#include \"freertos/FreeRTOS.h\""))
        
        // Test global declarations
        XCTAssertFalse(componentCode.globalDeclarations.isEmpty)
        XCTAssertTrue(componentCode.globalDeclarations.contains { $0.contains("kVendorId = 4660") }) // 0x1234
        XCTAssertTrue(componentCode.globalDeclarations.contains { $0.contains("kProductId = 22136") }) // 0x5678
        XCTAssertTrue(componentCode.globalDeclarations.contains { $0.contains("kDeviceTypeId") })
        
        // Test setup code
        XCTAssertFalse(componentCode.setupCode.isEmpty)
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::node::create") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::endpoint::create") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::start") })
        
        // Test callback definitions
        XCTAssertFalse(componentCode.classDefinitions.isEmpty)
        XCTAssertTrue(componentCode.classDefinitions.contains { $0.contains("app_event_cb") })
        XCTAssertTrue(componentCode.classDefinitions.contains { $0.contains("app_attribute_cb") })
    }
    
    func testMatterCodeGenerationWithCommissioning() throws {
        let commissioning = CommissioningConfig(
            discriminator: 1234,
            passcode: 87654321
        )
        let config = MatterConfig(
            deviceType: "on_off_light",
            commissioning: commissioning
        )
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        let componentCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test commissioning parameters in global declarations
        XCTAssertTrue(componentCode.globalDeclarations.contains { $0.contains("kDiscriminator = 1234") })
        XCTAssertTrue(componentCode.globalDeclarations.contains { $0.contains("kSetupPinCode = 87654321") })
        
        // Test commissioning setup in setup code
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::set_custom_dac_provider") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::set_custom_commissionable_data_provider") })
    }
    
    func testMatterCodeGenerationWithThread() throws {
        let thread = ThreadConfig(
            enabled: true,
            dataset: "0e080000000000000001000035060004001fffe0020811111111222222220708fd00"
        )
        let network = MatterNetworkConfig(transport: "thread")
        let config = MatterConfig(
            deviceType: "on_off_light",
            thread: thread,
            network: network
        )
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        let componentCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test Thread configuration in setup code
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("#if CONFIG_OPENTHREAD_ENABLED") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::set_custom_thread_dataset") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("#endif // CONFIG_OPENTHREAD_ENABLED") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains(thread.dataset!) })
    }
    
    func testMatterCodeGenerationWithWiFi() throws {
        let network = MatterNetworkConfig(transport: "wifi")
        let config = MatterConfig(
            deviceType: "on_off_light",
            network: network
        )
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        let componentCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test WiFi configuration
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("WiFi transport configuration") })
        XCTAssertTrue(componentCode.setupCode.contains { $0.contains("esp_matter::set_custom_attribute_callback") })
    }
    
    func testDeviceTypeClusters() throws {
        let deviceTypes: [(MatterDeviceType, [String])] = [
            (.onOffLight, ["esp_matter::identify::create", "esp_matter::on_off::create"]),
            (
                .dimmableLight,
                ["esp_matter::identify::create", "esp_matter::on_off::create", "esp_matter::level_control::create"]
            ),
            (.temperatureSensor, ["esp_matter::identify::create", "esp_matter::temperature_measurement::create"]),
            (.humiditySensor, ["esp_matter::identify::create", "esp_matter::relative_humidity_measurement::create"])
        ]
        
        for (deviceType, expectedClusters) in deviceTypes {
            let config = MatterConfig.create(deviceType: deviceType)
            
            let context = CodeGenerationContext(
                configuration: ESPHomeConfiguration(
                    esphomeSwift: CoreConfig(name: "test"),
                    esp32: ESP32Config(
                        board: "esp32-c6-devkitc-1",
                        framework: FrameworkConfig(type: .espIDF)
                    )
                ),
                outputDirectory: "/tmp",
                targetBoard: "esp32-c6-devkitc-1",
                framework: .espIDF
            )
            
            let componentCode = try MatterCodeGenerator.generateMatterCode(
                config: config,
                context: context
            )
            
            // Test that expected clusters are created
            for expectedCluster in expectedClusters {
                XCTAssertTrue(componentCode.setupCode.contains { $0.contains(expectedCluster) },
                              "Device type \(deviceType) should create cluster: \(expectedCluster)")
            }
        }
    }
    
    func testInvalidDeviceType() throws {
        let config = MatterConfig(deviceType: "invalid_device_type")
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        let componentCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Should generate with default device type ID
        XCTAssertTrue(componentCode.globalDeclarations.contains { $0.contains("kDeviceTypeId = 0x0000") })
    }
    
    func testThreadTransportWithoutThreadConfig() throws {
        let network = MatterNetworkConfig(transport: "thread")
        let config = MatterConfig(
            deviceType: "on_off_light",
            network: network
        )
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        XCTAssertThrowsError(try MatterCodeGenerator.generateMatterCode(config: config, context: context)) { error in
            XCTAssertTrue(error is MatterCodeGenerationError)
            if case .inconsistentConfiguration = error as? MatterCodeGenerationError ?? MatterCodeGenerationError.inconsistentConfiguration(reason: "Unexpected error type") {
                // Expected
            } else {
                XCTFail("Should throw inconsistent configuration error")
            }
        }
    }
    
    func testUnsupportedTransport() throws {
        let network = MatterNetworkConfig(transport: "ethernet")
        let config = MatterConfig(
            deviceType: "on_off_light",
            network: network
        )
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        XCTAssertThrowsError(try MatterCodeGenerator.generateMatterCode(config: config, context: context)) { error in
            XCTAssertTrue(error is MatterCodeGenerationError)
            if case .unsupportedTransport(let transport) = error as? MatterCodeGenerationError ?? MatterCodeGenerationError.inconsistentConfiguration(reason: "Unexpected error type") {
                XCTAssertEqual(transport, "ethernet")
            } else {
                XCTFail("Should throw unsupported transport error")
            }
        }
    }
    
    func testMatterCodeGenerationErrorDescriptions() {
        let errors: [MatterCodeGenerationError] = [
            .unsupportedDeviceType("invalid_type"),
            .unsupportedTransport(transport: "ethernet"),
            .inconsistentConfiguration(reason: "Missing Thread config"),
            .missingRequiredConfiguration(parameter: "vendor_id")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testLoopCodeGeneration() throws {
        let config = MatterConfig(deviceType: "on_off_light")
        
        let context = CodeGenerationContext(
            configuration: ESPHomeConfiguration(
                esphomeSwift: CoreConfig(name: "test"),
                esp32: ESP32Config(
                    board: "esp32-c6-devkitc-1",
                    framework: FrameworkConfig(type: .espIDF)
                )
            ),
            outputDirectory: "/tmp",
            targetBoard: "esp32-c6-devkitc-1",
            framework: .espIDF
        )
        
        let componentCode = try MatterCodeGenerator.generateMatterCode(
            config: config,
            context: context
        )
        
        // Test that loop code contains appropriate comments
        XCTAssertFalse(componentCode.loopCode.isEmpty)
        XCTAssertTrue(componentCode.loopCode.contains { $0.contains("Matter runs its own event loop") })
    }
}