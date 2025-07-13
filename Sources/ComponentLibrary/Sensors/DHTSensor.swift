import Foundation
import ESPHomeSwiftCore

/// DHT temperature and humidity sensor factory
public struct DHTSensorFactory: ComponentFactory {
    public typealias ConfigType = SensorConfig
    
    public let platform = "dht"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin", "model"]
    public let optionalProperties = ["update_interval", "temperature", "humidity"]
    
    private let pinValidator: PinValidator
    
    public init(pinValidator: PinValidator = PinValidator()) {
        self.pinValidator = pinValidator
    }
    
    public func validate(config: SensorConfig) throws {
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
        
        try pinValidator.validatePin(pin, requirements: .input)
    }
    
    public func generateCode(config: SensorConfig, context: CodeGenerationContext) throws -> ComponentCode {
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
        
        // Generate temperature reading code
        if let tempConfig = config.temperature {
            let tempId = tempConfig.id ?? "\(componentId)_temperature"
            loopCode.append("""
            float \(tempId)_value = \(componentId).readTemperature();
            if (!isnan(\(tempId)_value)) {
                // TODO: Send temperature value via API
                printf("Temperature: %.2f°C\\n", \(tempId)_value);
            }
            """)
        }
        
        // Generate humidity reading code
        if let humConfig = config.humidity {
            let humId = humConfig.id ?? "\(componentId)_humidity"
            loopCode.append("""
            float \(humId)_value = \(componentId).readHumidity();
            if (!isnan(\(humId)_value)) {
                // TODO: Send humidity value via API
                printf("Humidity: %.2f%%\\n", \(humId)_value);
            }
            """)
        }
        
        return ComponentCode(
            headerIncludes: headerIncludes,
            globalDeclarations: globalDeclarations,
            setupCode: setupCode,
            loopCode: loopCode
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
}