import Foundation
import ESPHomeSwiftCore

/// GPIO-based binary sensor factory
public class GPIOBinarySensorFactory: ComponentFactory {
    public let platform = "gpio"
    public let componentType = ComponentType.binarySensor
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "device_class", "inverted", "filters"]
    
    public func validate(config: ComponentConfig) throws {
        guard let sensorConfig = config as? BinarySensorConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected BinarySensorConfig"
            )
        }
        
        // Validate required pin
        guard sensorConfig.pin != nil else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Validate pin is input-capable
        if let pin = sensorConfig.pin {
            try validateInputPin(pin)
        }
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        guard let sensorConfig = config as? BinarySensorConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected BinarySensorConfig"
            )
        }
        
        let pinNumber = extractPinNumber(sensorConfig.pin!)
        let componentId = sensorConfig.id ?? "binary_sensor_\(pinNumber)"
        let inverted = sensorConfig.inverted ?? false
        let pullMode = determinePullMode(sensorConfig.pin!)
        
        let headerIncludes = [
            "#include \"driver/gpio.h\""
        ]
        
        let globalDeclarations = [
            "bool \(componentId)_last_state = false;",
            "unsigned long \(componentId)_last_change = 0;"
        ]
        
        let setupCode = [
            "gpio_config_t \(componentId)_config = {};",
            "\(componentId)_config.pin_bit_mask = (1ULL << \(pinNumber));",
            "\(componentId)_config.mode = GPIO_MODE_INPUT;",
            "\(componentId)_config.pull_up_en = \(pullMode == "pullup" ? "GPIO_PULLUP_ENABLE" : "GPIO_PULLUP_DISABLE");",
            "\(componentId)_config.pull_down_en = \(pullMode == "pulldown" ? "GPIO_PULLDOWN_ENABLE" : "GPIO_PULLDOWN_DISABLE");",
            "\(componentId)_config.intr_type = GPIO_INTR_DISABLE;",
            "gpio_config(&\(componentId)_config);",
            "\(componentId)_last_state = gpio_get_level(GPIO_NUM_\(pinNumber))\(inverted ? " == 0" : " == 1");"
        ]
        
        let loopCode = [
            """
            // Read \(componentId)
            bool \(componentId)_current_raw = gpio_get_level(GPIO_NUM_\(pinNumber)) == 1;
            bool \(componentId)_current_state = \(componentId)_current_raw\(inverted ? " == false" : "");
            
            if (\(componentId)_current_state != \(componentId)_last_state) {
                unsigned long now = millis();
                
                // Simple debouncing - wait 50ms between state changes
                if (now - \(componentId)_last_change > 50) {
                    \(componentId)_last_state = \(componentId)_current_state;
                    \(componentId)_last_change = now;
                    
                    Serial.printf("\(sensorConfig.name ?? componentId): %s\\n", \(componentId)_current_state ? "ON" : "OFF");
                    // TODO: Send state via API
                    // TODO: Apply filters if configured
                }
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
    
    private func validateInputPin(_ pin: PinConfig) throws {
        let pinNum = extractPinNumber(pin)
        
        if pinNum < 0 || pinNum > 48 {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "pin",
                value: String(pinNum),
                reason: "GPIO pin must be between 0 and 48"
            )
        }
        
        // All GPIO pins on ESP32-C6 can be used as input
        // But some pins have special functions we should warn about
        let specialPins = [0: "Boot button", 9: "Boot mode"]
        if let specialFunction = specialPins[pinNum] {
            // In a real implementation, we might log a warning here
            // For now, we'll allow it but could add validation
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
    
    private func determinePullMode(_ pin: PinConfig) -> String {
        // Determine appropriate pull mode based on pin mode configuration
        if let mode = pin.mode {
            switch mode {
            case .inputPullup:
                return "pullup"
            case .inputPulldown:
                return "pulldown"
            default:
                return "none"
            }
        }
        
        // Default to pullup for most binary sensors
        return "pullup"
    }
}