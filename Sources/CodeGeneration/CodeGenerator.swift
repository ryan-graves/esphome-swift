import Foundation
import ESPHomeSwiftCore
import ComponentLibrary
import MatterSupport
import Logging

/// Main code generation engine for ESPHome Swift
public class CodeGenerator {
    private let logger = Logger(label: "CodeGenerator")
    private let componentRegistry = ComponentRegistry.shared
    
    public init() {}
    
    /// Generate Embedded Swift code from configuration
    public func generateCode(
        from configuration: ESPHomeConfiguration,
        outputDirectory: String
    ) throws -> GeneratedProject {
        logger.info("Starting code generation for project: \(configuration.esphomeSwift.name)")
        
        let context = CodeGenerationContext(
            configuration: configuration,
            outputDirectory: outputDirectory,
            targetBoard: configuration.esp32.board,
            framework: configuration.esp32.framework.type
        )
        
        // Collect all component code
        var allComponentCode: [ComponentCode] = []
        
        // Generate sensor code
        if let sensors = configuration.sensor {
            for sensor in sensors {
                if let factory = componentRegistry.factory(for: sensor.platform, componentType: .sensor) {
                    let code = try factory.generateCodeAny(config: sensor, context: context)
                    allComponentCode.append(code)
                } else {
                    logger.warning("Unknown sensor platform: \(sensor.platform)")
                }
            }
        }
        
        // Generate switch code
        if let switches = configuration.`switch` {
            for switchConfig in switches {
                if let factory = componentRegistry.factory(for: switchConfig.platform, componentType: .`switch`) {
                    let code = try factory.generateCodeAny(config: switchConfig, context: context)
                    allComponentCode.append(code)
                } else {
                    logger.warning("Unknown switch platform: \(switchConfig.platform)")
                }
            }
        }
        
        // Generate light code
        if let lights = configuration.light {
            for light in lights {
                if let factory = componentRegistry.factory(for: light.platform, componentType: .light) {
                    let code = try factory.generateCodeAny(config: light, context: context)
                    allComponentCode.append(code)
                } else {
                    logger.warning("Unknown light platform: \(light.platform)")
                }
            }
        }
        
        // Generate binary sensor code
        if let binarySensors = configuration.binary_sensor {
            for sensor in binarySensors {
                if let factory = componentRegistry.factory(for: sensor.platform, componentType: .binarySensor) {
                    let code = try factory.generateCodeAny(config: sensor, context: context)
                    allComponentCode.append(code)
                } else {
                    logger.warning("Unknown binary sensor platform: \(sensor.platform)")
                }
            }
        }
        
        // Generate Matter code if enabled
        if let matterConfig = configuration.matter, matterConfig.enabled {
            logger.info("Generating Matter protocol support")
            let matterCode = try MatterCodeGenerator.generateMatterCode(
                config: matterConfig,
                context: context
            )
            allComponentCode.append(matterCode)
        }
        
        // Combine all component code
        let combinedCode = combineComponentCode(allComponentCode)
        
        // Generate main application files
        let mainCpp = try generateMainCpp(
            configuration: configuration,
            componentCode: combinedCode,
            allComponentCodes: allComponentCode,
            context: context
        )
        
        let cmakeLists = try generateCMakeLists(
            configuration: configuration,
            context: context
        )
        
        let sdkConfig = try generateSDKConfig(
            configuration: configuration,
            context: context
        )
        
        logger.info("Code generation completed successfully")
        
        return GeneratedProject(
            mainCpp: mainCpp,
            cmakeLists: cmakeLists,
            sdkConfig: sdkConfig,
            componentCode: combinedCode
        )
    }
    
    /// Combine component code from all components
    private func combineComponentCode(_ componentCodes: [ComponentCode]) -> ComponentCode {
        var allHeaderIncludes: Set<String> = []
        var allGlobalDeclarations: [String] = []
        var allSetupCode: [String] = []
        var allLoopCode: [String] = []
        var allClassDefinitions: [String] = []
        var allApiCode: [String] = []
        
        for code in componentCodes {
            allHeaderIncludes.formUnion(code.headerIncludes)
            allGlobalDeclarations.append(contentsOf: code.globalDeclarations)
            allSetupCode.append(contentsOf: code.setupCode)
            allLoopCode.append(contentsOf: code.loopCode)
            allClassDefinitions.append(contentsOf: code.classDefinitions)
            allApiCode.append(contentsOf: code.apiCode)
        }
        
        return ComponentCode(
            headerIncludes: Array(allHeaderIncludes).sorted(),
            globalDeclarations: allGlobalDeclarations,
            setupCode: allSetupCode,
            loopCode: allLoopCode,
            classDefinitions: allClassDefinitions,
            apiCode: allApiCode
        )
    }
    
    /// Generate main.cpp file
    private func generateMainCpp(
        configuration: ESPHomeConfiguration,
        componentCode: ComponentCode,
        allComponentCodes: [ComponentCode],
        context: CodeGenerationContext
    ) throws -> String {
        var cpp = ""
        
        // Standard includes
        cpp += """
        #include <stdio.h>
        #include <freertos/FreeRTOS.h>
        #include <freertos/task.h>
        #include <esp_system.h>
        #include <esp_log.h>
        #include <nvs_flash.h>
        
        """
        
        // Component-specific includes
        for include in componentCode.headerIncludes {
            cpp += "\(include)\n"
        }
        
        cpp += "\n"
        
        // Global declarations
        cpp += "// Global component declarations\n"
        for declaration in componentCode.globalDeclarations {
            cpp += "\(declaration)\n"
        }
        
        cpp += "\n"
        
        // Component function definitions
        cpp += "// Component function definitions\n"
        for definition in componentCode.classDefinitions {
            cpp += "\(definition)\n\n"
        }
        
        // Component API integration code
        if configuration.api != nil && !componentCode.apiCode.isEmpty {
            cpp += "// Component API integration\n"
            for apiCode in componentCode.apiCode {
                cpp += "\(apiCode)\n\n"
            }
        }
        
        // WiFi setup function (if WiFi is configured)
        if configuration.wifi != nil {
            cpp += try generateWiFiSetup(configuration: configuration)
        }
        
        // API setup function (if API is configured)
        if configuration.api != nil {
            cpp += try generateAPISetup(configuration: configuration)
        }
        
        // Setup function
        cpp += """
        void setup() {
            // Initialize NVS
            esp_err_t ret = nvs_flash_init();
            if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
                ESP_ERROR_CHECK(nvs_flash_erase());
                ret = nvs_flash_init();
            }
            ESP_ERROR_CHECK(ret);
            
            // Initialize serial
            printf("\\n");
            printf("ESPHome Swift - \\(configuration.esphomeSwift.name)\\n");
            printf("Board: \\(configuration.esp32.board)\\n");
            printf("Framework: \\(configuration.esp32.framework.type.rawValue)\\n");
            printf("\\n");
            
        """
        
        // Component setup code
        cpp += "    // Component setup\n"
        for setupLine in componentCode.setupCode {
            cpp += "    \(setupLine)\n"
        }
        
        // WiFi setup
        if configuration.wifi != nil {
            cpp += "\n    // WiFi setup\n"
            cpp += "    wifi_setup();\n"
        }
        
        // API setup
        if configuration.api != nil {
            cpp += "\n    // API setup\n"
            cpp += "    api_setup();\n"
            
            // Add component API registration calls
            if !componentCode.apiCode.isEmpty {
                cpp += "\n    // Component API registration\n"
                // Generate registration calls for each component
                for componentCodeItem in allComponentCodes {
                    if let config = componentCodeItem.config {
                        let name = config.name ?? config.id ?? "unknown"
                        let safeName = name.replacingOccurrences(of: " ", with: "_")
                        
                        // Check if this component has temperature/humidity sensors (DHT case)
                        if componentCodeItem.apiCode.contains(where: { $0.contains("\(safeName)_temperature_register_api") }) {
                            cpp += "    \(safeName)_temperature_register_api();\n"
                        }
                        if componentCodeItem.apiCode.contains(where: { $0.contains("\(safeName)_humidity_register_api") }) {
                            cpp += "    \(safeName)_humidity_register_api();\n"
                        }
                        
                        // Generic component registration
                        if componentCodeItem.apiCode.contains(where: { $0.contains("\(safeName)_register_api") }) {
                            cpp += "    \(safeName)_register_api();\n"
                        }
                    }
                }
            }
        }
        
        cpp += """
            
            printf("Setup completed successfully\\n");
        }
        
        """
        
        // Loop function
        cpp += """
        void loop() {
            // Component loop code
        """
        
        for loopLine in componentCode.loopCode {
            cpp += "    \(loopLine)\n"
        }
        
        cpp += """
            
            // Small delay to prevent watchdog issues
            vTaskDelay(pdMS_TO_TICKS(10));
        }
        
        // Main entry point for ESP-IDF
        extern "C" void app_main() {
            setup();
            
            while (true) {
                loop();
            }
        }
        """
        
        return cpp
    }
    
    /// Generate WiFi setup code
    private func generateWiFiSetup(configuration: ESPHomeConfiguration) throws -> String {
        guard configuration.wifi != nil else {
            return ""
        }
        
        return """
        #include <esp_wifi.h>
        #include <esp_event.h>
        
        static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                                      int32_t event_id, void* event_data) {
            if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
                esp_wifi_connect();
            } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
                printf("WiFi disconnected, attempting reconnect...\\n");
                esp_wifi_connect();
            } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
                ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
                printf("WiFi connected! IP: " IPSTR "\\n", IP2STR(&event->ip_info.ip));
            }
        }
        
        void wifi_setup() {
            ESP_ERROR_CHECK(esp_netif_init());
            ESP_ERROR_CHECK(esp_event_loop_create_default());
            esp_netif_create_default_wifi_sta();
            
            wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
            ESP_ERROR_CHECK(esp_wifi_init(&cfg));
            
            ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL));
            ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL));
            
            wifi_config_t wifi_config = {};
            strncpy((char*)wifi_config.sta.ssid, "\\(wifi.ssid)", sizeof(wifi_config.sta.ssid) - 1);
            strncpy((char*)wifi_config.sta.password, "\\(wifi.password)", sizeof(wifi_config.sta.password) - 1);
            
            ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
            ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
            ESP_ERROR_CHECK(esp_wifi_start());
            
            printf("WiFi setup completed\\n");
        }
        
        """
    }
    
    /// Generate API setup code
    private func generateAPISetup(configuration: ESPHomeConfiguration) throws -> String {
        guard let apiConfig = configuration.api else {
            return ""
        }
        
        // Generate the full API server implementation
        let deviceName = configuration.esphomeSwift.name
        let boardModel = configuration.esp32.board
        let apiServerCode = ESPHomeAPIServer.generateAPIServerCode(
            config: apiConfig,
            deviceName: deviceName,
            boardModel: boardModel
        )
        let componentAPICode = ESPHomeAPIServer.generateComponentAPICode()
        
        return """
        // ===== ESPHome Native API Server =====
        \(componentAPICode)
        
        \(apiServerCode)
        
        """
    }
    
    /// Generate CMakeLists.txt
    private func generateCMakeLists(
        configuration: ESPHomeConfiguration,
        context: CodeGenerationContext
    ) throws -> String {
        return """
        cmake_minimum_required(VERSION 3.16)
        
        # Set project name based on ESPHome Swift configuration
        set(PROJECT_NAME "\\(configuration.esphomeSwift.name)")
        
        include($ENV{IDF_PATH}/tools/cmake/project.cmake)
        project(${PROJECT_NAME})
        """
    }
    
    /// Generate sdkconfig
    private func generateSDKConfig(
        configuration: ESPHomeConfiguration,
        context: CodeGenerationContext
    ) throws -> String {
        var config = """
        # ESPHome Swift generated configuration
        # Board: \\(configuration.esp32.board)
        # Framework: \\(configuration.esp32.framework.type.rawValue)
        
        # Compiler configuration
        CONFIG_COMPILER_OPTIMIZATION_SIZE=y
        CONFIG_COMPILER_CXX_EXCEPTIONS=n
        CONFIG_COMPILER_CXX_RTTI=n
        
        # FreeRTOS configuration
        CONFIG_FREERTOS_HZ=1000
        
        # Serial configuration
        CONFIG_ESP_CONSOLE_UART_DEFAULT=y
        CONFIG_ESP_CONSOLE_UART_BAUDRATE=115200
        
        # Logging
        CONFIG_LOG_DEFAULT_LEVEL_INFO=y
        
        """
        
        // Add WiFi configuration if needed
        if configuration.wifi != nil {
            config += """
            # WiFi configuration
            CONFIG_ESP32_WIFI_ENABLED=y
            CONFIG_ESP32_WIFI_STATIC_RX_BUFFER_NUM=10
            CONFIG_ESP32_WIFI_DYNAMIC_RX_BUFFER_NUM=32
            CONFIG_ESP32_WIFI_TX_BUFFER_TYPE_DYNAMIC=y
            CONFIG_ESP32_WIFI_DYNAMIC_TX_BUFFER_NUM=32
            
            """
        }
        
        return config
    }
}

/// Generated project structure
public struct GeneratedProject {
    public let mainCpp: String
    public let cmakeLists: String
    public let sdkConfig: String
    public let componentCode: ComponentCode
    
    public init(
        mainCpp: String,
        cmakeLists: String,
        sdkConfig: String,
        componentCode: ComponentCode
    ) {
        self.mainCpp = mainCpp
        self.cmakeLists = cmakeLists
        self.sdkConfig = sdkConfig
        self.componentCode = componentCode
    }
}