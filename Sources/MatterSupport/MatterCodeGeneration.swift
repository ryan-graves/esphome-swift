import Foundation
import ESPHomeSwiftCore
import ComponentLibrary

/// Matter code generation utilities for ESP-Matter SDK integration
public struct MatterCodeGenerator {
    
    /// Generates Matter initialization code for ESP-IDF projects
    /// - Parameters:
    ///   - config: Matter configuration
    ///   - context: Code generation context
    /// - Returns: ComponentCode with Matter setup and initialization
    public static func generateMatterCode(
        config: MatterConfig,
        context: CodeGenerationContext
    ) throws -> ComponentCode {
        
        let headerIncludes = generateHeaderIncludes()
        let globalDeclarations = try generateGlobalDeclarations(config: config)
        let setupCode = try generateSetupCode(config: config, context: context)
        let loopCode = generateLoopCode(config: config)
        let classDefinitions = try generateMatterCallbacks(config: config)
        
        return ComponentCode(
            headerIncludes: headerIncludes,
            globalDeclarations: globalDeclarations,
            setupCode: setupCode,
            loopCode: loopCode,
            classDefinitions: classDefinitions
        )
    }
    
    /// Generates required header includes for Matter functionality
    private static func generateHeaderIncludes() -> [String] {
        return [
            "#include \"esp_matter.h\"",
            "#include \"esp_matter_console.h\"",
            "#include \"esp_matter_ota.h\"",
            "#include \"app_priv.h\"",
            "#include \"app/server/CommissioningWindowManager.h\"",
            "#include \"app/server/Server.h\"",
            "#include \"credentials/FabricTable.h\"",
            "#include \"esp_log.h\"",
            "#include \"freertos/FreeRTOS.h\"",
            "#include \"freertos/task.h\""
        ]
    }
    
    /// Generates global variable declarations for Matter
    private static func generateGlobalDeclarations(config: MatterConfig) throws -> [String] {
        var declarations: [String] = []
        
        // Basic Matter node variables
        declarations.append("static const char *TAG = \"MATTER_DEVICE\";")
        declarations.append("static uint16_t matter_endpoint_id = 0;")
        
        // Device identification
        declarations.append("static constexpr uint32_t kVendorId = \(config.vendorId);")
        declarations.append("static constexpr uint32_t kProductId = \(config.productId);")
        if let deviceType = config.matterDeviceType {
            declarations.append("static constexpr uint32_t kDeviceTypeId = \(deviceType.deviceTypeId);")
        } else {
            declarations.append("static constexpr uint32_t kDeviceTypeId = 0x0000; // Unknown device type")
        }
        
        // Commissioning parameters
        if let commissioning = config.commissioning {
            declarations.append("static constexpr uint16_t kDiscriminator = \(commissioning.discriminator);")
            declarations.append("static constexpr uint32_t kSetupPinCode = \(commissioning.passcode);")
        }
        
        return declarations
    }
    
    /// Generates Matter setup code for the main setup() function
    private static func generateSetupCode(
        config: MatterConfig,
        context: CodeGenerationContext
    ) throws -> [String] {
        var setupCode: [String] = []
        
        // Initialize Matter
        setupCode.append("ESP_LOGI(TAG, \"Starting Matter device setup\");")
        
        // Matter node initialization
        setupCode.append("esp_matter::node::config_t node_config;")
        setupCode.append("esp_matter::node_t *node = esp_matter::node::create(&node_config);")
        setupCode.append("if (!node) {")
        setupCode.append("    ESP_LOGE(TAG, \"Failed to create Matter node\");")
        setupCode.append("    return;")
        setupCode.append("}")
        
        // Create root endpoint
        setupCode.append("esp_matter::endpoint::config_t endpoint_config;")
        setupCode.append("endpoint_config.flags = ESP_MATTER_ENDPOINT_FLAG_DESTROYABLE;")
        setupCode.append("esp_matter::endpoint_t *endpoint = esp_matter::endpoint::create(node, &endpoint_config);")
        
        // Add device type to endpoint
        setupCode.append("esp_matter::cluster_t *descriptor_cluster = esp_matter::descriptor::create(endpoint, CLUSTER_FLAG_SERVER);")
        setupCode.append("esp_matter::descriptor::config_t descriptor_config;")
        setupCode.append("descriptor_config.device_type_id = kDeviceTypeId;")
        setupCode.append("esp_matter::descriptor::add_device_type(descriptor_cluster, kDeviceTypeId, 1);")
        
        // Add required clusters based on device type
        if let deviceType = config.matterDeviceType {
            try setupCode.append(contentsOf: generateDeviceTypeClusters(deviceType))
        }
        
        // Set commissioning parameters
        if let commissioning = config.commissioning {
            setupCode.append("esp_matter::set_custom_dac_provider(esp_matter_dac_provider_create());")
            setupCode.append("esp_matter::set_custom_commissionable_data_provider(esp_matter_commissionable_data_provider_create());")
        }
        
        // Configure network transport
        if let network = config.network {
            try setupCode.append(contentsOf: generateNetworkConfig(network, threadConfig: config.thread))
        }
        
        // Start Matter
        setupCode.append("esp_matter::start(app_event_cb);")
        setupCode.append("ESP_LOGI(TAG, \"Matter device started successfully\");")
        
        return setupCode
    }
    
    /// Generates device-type specific cluster creation code
    private static func generateDeviceTypeClusters(_ deviceType: MatterDeviceType) throws -> [String] {
        var clusterCode: [String] = []
        
        // Add required clusters for the device type
        for cluster in deviceType.requiredClusters {
            switch cluster {
            case .identify:
                clusterCode.append("esp_matter::identify::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .groups:
                clusterCode.append("esp_matter::groups::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .scenes:
                clusterCode.append("esp_matter::scenes::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .descriptor:
                // Descriptor cluster is already added above for all device types
                continue
                
            case .onOff:
                clusterCode.append("esp_matter::on_off::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::on_off::get_feature_map_value(0));")
                
            case .levelControl:
                clusterCode.append("esp_matter::level_control::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::level_control::get_feature_map_value(0));")
                
            case .colorControl:
                clusterCode.append("esp_matter::color_control::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::color_control::get_feature_map_value(esp_matter::color_control::feature::hue_saturation::get_id()));")
                
            case .switch:
                clusterCode.append("esp_matter::switch_cluster::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .temperatureMeasurement:
                clusterCode.append("esp_matter::temperature_measurement::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .relativeHumidityMeasurement:
                clusterCode.append("esp_matter::relative_humidity_measurement::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .pressureMeasurement:
                clusterCode.append("esp_matter::pressure_measurement::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .flowMeasurement:
                clusterCode.append("esp_matter::flow_measurement::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .illuminanceMeasurement:
                clusterCode.append("esp_matter::illuminance_measurement::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .occupancySensing:
                clusterCode.append("esp_matter::occupancy_sensing::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .booleanState:
                clusterCode.append("esp_matter::boolean_state::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .airQuality:
                clusterCode.append("esp_matter::air_quality::create(endpoint, CLUSTER_FLAG_SERVER);")
                
            case .doorLock:
                clusterCode.append("esp_matter::door_lock::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::door_lock::get_feature_map_value(esp_matter::door_lock::feature::pin_credential::get_id()));")
                
            case .thermostat:
                clusterCode.append("esp_matter::thermostat::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::thermostat::get_feature_map_value(esp_matter::thermostat::feature::heating::get_id() | esp_matter::thermostat::feature::cooling::get_id()));")
                
            case .fanControl:
                clusterCode.append("esp_matter::fan_control::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::fan_control::get_feature_map_value(esp_matter::fan_control::feature::multi_speed::get_id()));")
                
            case .windowCovering:
                clusterCode.append("esp_matter::window_covering::create(endpoint, CLUSTER_FLAG_SERVER, esp_matter::window_covering::get_feature_map_value(esp_matter::window_covering::feature::lift::get_id()));")
            }
        }
        
        return clusterCode
    }
    
    /// Generates network configuration code
    private static func generateNetworkConfig(
        _ network: MatterNetworkConfig,
        threadConfig: ThreadConfig?
    ) throws -> [String] {
        var networkCode: [String] = []
        
        switch network.transport {
        case "wifi":
            networkCode.append("// WiFi transport configuration")
            networkCode.append("esp_matter::set_custom_attribute_callback(app_attribute_cb);")
            
        case "thread":
            guard let thread = threadConfig, thread.enabled else {
                throw MatterCodeGenerationError.inconsistentConfiguration(
                    reason: "Thread transport requires Thread configuration"
                )
            }
            
            networkCode.append("// Thread transport configuration")
            networkCode.append("#if CONFIG_OPENTHREAD_ENABLED")
            
            if let dataset = thread.dataset {
                networkCode.append("esp_matter::set_custom_thread_dataset(\"\(dataset)\");")
            }
            
            networkCode.append("#endif // CONFIG_OPENTHREAD_ENABLED")
            
        case "ethernet":
            throw MatterCodeGenerationError.unsupportedTransport(transport: "ethernet")
            
        default:
            throw MatterCodeGenerationError.unsupportedTransport(transport: network.transport)
        }
        
        return networkCode
    }
    
    /// Generates Matter event loop code
    private static func generateLoopCode(config: MatterConfig) -> [String] {
        return [
            "// Matter runs its own event loop via esp_matter::start()",
            "// Component-specific Matter attribute updates can be added here"
        ]
    }
    
    /// Generates Matter callback function definitions
    private static func generateMatterCallbacks(config: MatterConfig) throws -> [String] {
        var callbacks: [String] = []
        
        // Event callback function
        callbacks.append("""
        esp_err_t app_event_cb(const ChipDeviceEvent *event, intptr_t arg) {
            switch (event->Type) {
                case chip::DeviceLayer::DeviceEventType::kWiFiConnectivityChange:
                    ESP_LOGI(TAG, "WiFi connectivity changed");
                    break;
                case chip::DeviceLayer::DeviceEventType::kCommissioningComplete:
                    ESP_LOGI(TAG, "Commissioning complete");
                    break;
                default:
                    break;
            }
            return ESP_OK;
        }
        """)
        
        // Attribute callback function
        callbacks.append("""
        esp_err_t app_attribute_cb(esp_matter::attribute::callback_type_t type, uint16_t endpoint_id, uint32_t cluster_id,
                                  uint32_t attribute_id, esp_matter::attribute::val_t *val, void *priv_data) {
            esp_err_t err = ESP_OK;
            
            if (type == esp_matter::attribute::PRE_UPDATE) {
                ESP_LOGI(TAG, "Attribute update: endpoint=0x%x, cluster=0x%x, attribute=0x%x", 
                        endpoint_id, cluster_id, attribute_id);
                        
                // Handle attribute updates here
                // This is where ESPHome Swift components would sync their state
            }
            
            return err;
        }
        """)
        
        return callbacks
    }
}

/// Matter code generation errors
public enum MatterCodeGenerationError: Error, LocalizedError {
    case unsupportedDeviceType(String)
    case unsupportedTransport(transport: String)
    case inconsistentConfiguration(reason: String)
    case missingRequiredConfiguration(parameter: String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedDeviceType(let deviceType):
            return "Unsupported Matter device type: \(deviceType)"
        case .unsupportedTransport(let transport):
            return "Unsupported network transport: \(transport)"
        case .inconsistentConfiguration(let reason):
            return "Inconsistent Matter configuration: \(reason)"
        case .missingRequiredConfiguration(let parameter):
            return "Missing required Matter configuration parameter: \(parameter)"
        }
    }
}