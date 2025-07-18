import Foundation
import ESPHomeSwiftCore

/// DHT temperature and humidity sensor factory
public struct DHTSensorFactory: ComponentFactory {
    public typealias ConfigType = SensorConfig
    
    public let platform = "dht"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin", "model"]
    public let optionalProperties = ["update_interval", "temperature", "humidity"]
    
    public init() {}
    
    public func validate(config: SensorConfig, board: String) throws {
        // Validate required pin
        guard let pin = config.pin else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Validate required model
        guard config.model != nil else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "model"
            )
        }
        
        let pinValidator = try createPinValidator(for: board)
        try pinValidator.validatePin(pin, requirements: .input)
    }
    
    public func generateCode(config: SensorConfig, context: CodeGenerationContext) throws -> ComponentCode {
        let boardDef = try getBoardDefinition(from: context)
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        let pinNumber = try pinValidator.extractPinNumber(from: config.pin!)
        let model = config.model!
        let componentId = config.id ?? "dht_sensor"
        
        let headerIncludes = [
            "#include \"DHT.h\""
        ]
        
        let globalDeclarations = [
            "DHT \(componentId)(\(pinNumber), \(dhtTypeConstant(model)));"
        ]
        
        let setupCode = [
            "\(componentId).begin();"
        ]
        
        var loopCode: [String] = []
        
        var apiCode: [String] = []
        
        // Generate temperature reading code
        if let tempConfig = config.temperature {
            let tempId = tempConfig.id ?? "\(componentId)_temperature"
            let tempKey = generateComponentKey(name: tempId, type: "sensor")
            
            apiCode.append("""
            // API integration for temperature sensor: \(tempId)
            static uint32_t \(tempId)_key = \(tempKey);
            static float \(tempId)_state = 0.0f;
            static bool \(tempId)_has_state = false;
            
            void \(tempId)_register_api() {
                api_register_sensor(\(tempKey), "\(tempId)", "\(tempId)", "temperature", "°C");
            }
            
            void \(tempId)_report_state(float value) {
                \(tempId)_state = value;
                \(tempId)_has_state = true;
                if (api_client_subscribed()) {
                    api_send_sensor_state(\(tempKey), value, false);
                }
            }
            """)
            
            loopCode.append("""
            float \(tempId)_value = \(componentId).readTemperature();
            if (!isnan(\(tempId)_value)) {
                \(tempId)_report_state(\(tempId)_value);
                printf("Temperature: %.2f°C\\n", \(tempId)_value);
            } else {
                \(tempId)_has_state = false;
                if (api_client_subscribed()) {
                    api_send_sensor_state(\(tempKey), 0.0f, true);
                }
            }
            """)
        }
        
        // Generate humidity reading code
        if let humConfig = config.humidity {
            let humId = humConfig.id ?? "\(componentId)_humidity"
            let humKey = generateComponentKey(name: humId, type: "sensor")
            
            apiCode.append("""
            // API integration for humidity sensor: \(humId)
            static uint32_t \(humId)_key = \(humKey);
            static float \(humId)_state = 0.0f;
            static bool \(humId)_has_state = false;
            
            void \(humId)_register_api() {
                api_register_sensor(\(humKey), "\(humId)", "\(humId)", "humidity", "%");
            }
            
            void \(humId)_report_state(float value) {
                \(humId)_state = value;
                \(humId)_has_state = true;
                if (api_client_subscribed()) {
                    api_send_sensor_state(\(humKey), value, false);
                }
            }
            """)
            
            loopCode.append("""
            float \(humId)_value = \(componentId).readHumidity();
            if (!isnan(\(humId)_value)) {
                \(humId)_report_state(\(humId)_value);
                printf("Humidity: %.2f%%\\n", \(humId)_value);
            } else {
                \(humId)_has_state = false;
                if (api_client_subscribed()) {
                    api_send_sensor_state(\(humKey), 0.0f, true);
                }
            }
            """)
        }
        
        return ComponentCode(
            headerIncludes: headerIncludes,
            globalDeclarations: globalDeclarations,
            setupCode: setupCode,
            loopCode: loopCode,
            apiCode: apiCode,
            config: config
        )
    }
    
    private func dhtTypeConstant(_ model: DHTModel) -> String {
        switch model {
        case .dht11:
            return "DHT11"
        case .dht22:
            return "DHT22"
        case .am2302:
            return "DHT22" // AM2302 uses same constant as DHT22
        }
    }
    
    /// Generate unique component key based on name and type
    private func generateComponentKey(name: String, type: String) -> UInt32 {
        // Simple hash function for generating unique keys
        let combined = "\(name)_\(type)"
        var hash: UInt32 = 0
        for char in combined.utf8 {
            hash = hash &* 31 &+ UInt32(char)
        }
        return hash
    }
}