import Foundation
import ESPHomeSwiftCore

/// DHT temperature and humidity sensor factory
public class DHTSensorFactory: ComponentFactory {
    public let platform = "dht"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin", "model"]
    public let optionalProperties = ["update_interval", "temperature", "humidity"]
    
    public func validate(config: ComponentConfig) throws {
        guard let sensorConfig = config as? SensorConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected SensorConfig"
            )
        }
        
        // Validate required pin
        guard sensorConfig.pin != nil else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Validate required model
        guard sensorConfig.model != nil else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "model"
            )
        }
        
        // Validate pin is valid GPIO
        if let pin = sensorConfig.pin {
            try validateGPIOPin(pin)
        }
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        guard let sensorConfig = config as? SensorConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected SensorConfig"
            )
        }
        
        let pinNumber = extractPinNumber(sensorConfig.pin!)
        let model = sensorConfig.model!
        let componentId = sensorConfig.id ?? "dht_sensor"
        
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
        if let tempConfig = sensorConfig.temperature {
            let tempId = tempConfig.id ?? "\(componentId)_temperature"
            loopCode.append("""
            float \(tempId)_value = \(componentId).readTemperature();
            if (!isnan(\(tempId)_value)) {
                // TODO: Send temperature value via API
                Serial.printf("Temperature: %.2f°C\\n", \(tempId)_value);
            }
            """)
        }
        
        // Generate humidity reading code
        if let humConfig = sensorConfig.humidity {
            let humId = humConfig.id ?? "\(componentId)_humidity"
            loopCode.append("""
            float \(humId)_value = \(componentId).readHumidity();
            if (!isnan(\(humId)_value)) {
                // TODO: Send humidity value via API
                Serial.printf("Humidity: %.2f%%\\n", \(humId)_value);
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
    
    private func validateGPIOPin(_ pin: PinConfig) throws {
        // Basic GPIO validation - in real implementation would check board-specific pins
        let pinNum = extractPinNumber(pin)
        if pinNum < 0 || pinNum > 48 {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "pin",
                value: String(pinNum),
                reason: "GPIO pin must be between 0 and 48"
            )
        }
    }
    
    private func extractPinNumber(_ pin: PinConfig) -> Int {
        switch pin.number {
        case .integer(let num):
            return num
        case .gpio(let gpio):
            // Extract number from "GPIO4" format
            let number = gpio.replacingOccurrences(of: "GPIO", with: "")
            return Int(number) ?? 0
        }
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