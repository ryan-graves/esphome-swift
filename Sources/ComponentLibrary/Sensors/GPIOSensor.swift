import Foundation
import ESPHomeSwiftCore

/// GPIO-based analog sensor factory
public class GPIOSensorFactory: ComponentFactory {
    public let platform = "adc"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "update_interval", "accuracy", "filters"]
    
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
        
        // Validate pin is ADC-capable
        if let pin = sensorConfig.pin {
            try validateADCPin(pin)
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
        let componentId = sensorConfig.id ?? "adc_sensor_\(pinNumber)"
        let updateInterval = parseUpdateInterval(sensorConfig.updateInterval ?? "60s")
        
        let headerIncludes = [
            "#include \"driver/adc.h\""
        ]
        
        let globalDeclarations = [
            "unsigned long \(componentId)_last_update = 0;",
            "const unsigned long \(componentId)_update_interval = \(updateInterval);"
        ]
        
        let setupCode = [
            "adc1_config_width(ADC_WIDTH_BIT_12);",
            "adc1_config_channel_atten(ADC1_CHANNEL_\(adcChannelForPin(pinNumber)), ADC_ATTEN_DB_11);"
        ]
        
        let loopCode = [
            """
            if (millis() - \(componentId)_last_update > \(componentId)_update_interval) {
                int \(componentId)_raw = adc1_get_raw(ADC1_CHANNEL_\(adcChannelForPin(pinNumber)));
                float \(componentId)_voltage = \(componentId)_raw * (3.3 / 4095.0);
                
                // TODO: Apply filters if configured
                // TODO: Send value via API
                Serial.printf("ADC Pin \(pinNumber): %.3fV (raw: %d)\\n", \(componentId)_voltage, \(componentId)_raw);
                
                \(componentId)_last_update = millis();
            }
            """
        ]
        
        return ComponentCode(
            headerIncludes: headerIncludes,
            globalDeclarations: globalDeclarations,
            setupCode: setupCode,
            loopCode: loopCode
        )
    }
    
    private func validateADCPin(_ pin: PinConfig) throws {
        let pinNum = extractPinNumber(pin)
        let adcPins = [0, 1, 2, 3, 4, 5, 6, 7] // ADC1 pins for ESP32-C6
        
        if !adcPins.contains(pinNum) {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "pin",
                value: String(pinNum),
                reason: "Pin must be ADC-capable (0-7 for ESP32-C6)"
            )
        }
    }
    
    private func extractPinNumber(_ pin: PinConfig) -> Int {
        switch pin.number {
        case .integer(let num):
            return num
        case .gpio(let gpio):
            let number = gpio.replacingOccurrences(of: "GPIO", with: "")
            return Int(number) ?? 0
        }
    }
    
    private func adcChannelForPin(_ pin: Int) -> Int {
        // Map GPIO pin to ADC1 channel for ESP32-C6
        return pin // Direct mapping for ESP32-C6
    }
    
    private func parseUpdateInterval(_ interval: String) -> Int {
        // Parse interval like "60s", "1000ms" to milliseconds
        if interval.hasSuffix("s") {
            let seconds = Int(interval.dropLast()) ?? 60
            return seconds * 1000
        } else if interval.hasSuffix("ms") {
            return Int(interval.dropLast(2)) ?? 60000
        } else {
            return Int(interval) ?? 60000
        }
    }
}