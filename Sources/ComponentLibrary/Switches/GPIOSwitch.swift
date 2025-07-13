import Foundation
import ESPHomeSwiftCore

/// GPIO-based switch factory
public class GPIOSwitchFactory: ComponentFactory {
    public let platform = "gpio"
    public let componentType = ComponentType.switch_
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "inverted", "restore_mode"]
    
    public func validate(config: ComponentConfig) throws {
        guard let switchConfig = config as? SwitchConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected SwitchConfig"
            )
        }
        
        // Validate required pin
        guard switchConfig.pin != nil else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Validate pin is output-capable
        if let pin = switchConfig.pin {
            try validateOutputPin(pin)
        }
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        guard let switchConfig = config as? SwitchConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected SwitchConfig"
            )
        }
        
        let pinNumber = extractPinNumber(switchConfig.pin!)
        let componentId = switchConfig.id ?? "gpio_switch_\(pinNumber)"
        let inverted = switchConfig.inverted ?? false
        let restoreMode = switchConfig.restoreMode ?? .restoreDefaultOff
        
        let headerIncludes = [
            "#include \"driver/gpio.h\""
        ]
        
        let globalDeclarations = [
            "bool \(componentId)_state = \(initialState(restoreMode));"
        ]
        
        let setupCode = [
            "gpio_config_t \(componentId)_config = {};",
            "\(componentId)_config.pin_bit_mask = (1ULL << \(pinNumber));",
            "\(componentId)_config.mode = GPIO_MODE_OUTPUT;",
            "\(componentId)_config.pull_up_en = GPIO_PULLUP_DISABLE;",
            "\(componentId)_config.pull_down_en = GPIO_PULLDOWN_DISABLE;",
            "\(componentId)_config.intr_type = GPIO_INTR_DISABLE;",
            "gpio_config(&\(componentId)_config);",
            "gpio_set_level(GPIO_NUM_\(pinNumber), \(componentId)_state \(inverted ? "? 0 : 1" : "? 1 : 0"));"
        ]
        
        let classDefinitions = [
            """
            void \(componentId)_turn_on() {
                \(componentId)_state = true;
                gpio_set_level(GPIO_NUM_\(pinNumber), \(inverted ? "0" : "1"));
                Serial.println("\(switchConfig.name ?? componentId): ON");
                // TODO: Send state via API
            }
            
            void \(componentId)_turn_off() {
                \(componentId)_state = false;
                gpio_set_level(GPIO_NUM_\(pinNumber), \(inverted ? "1" : "0"));
                Serial.println("\(switchConfig.name ?? componentId): OFF");
                // TODO: Send state via API
            }
            
            void \(componentId)_toggle() {
                if (\(componentId)_state) {
                    \(componentId)_turn_off();
                } else {
                    \(componentId)_turn_on();
                }
            }
            
            bool \(componentId)_get_state() {
                return \(componentId)_state;
            }
            """
        ]
        
        return ComponentCode(
            headerIncludes: headerIncludes,
            globalDeclarations: globalDeclarations,
            setupCode: setupCode,
            classDefinitions: classDefinitions
        )
    }
    
    private func validateOutputPin(_ pin: PinConfig) throws {
        let pinNum = extractPinNumber(pin)
        
        // Basic validation - in real implementation would check board-specific constraints
        if pinNum < 0 || pinNum > 48 {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "pin",
                value: String(pinNum),
                reason: "GPIO pin must be between 0 and 48"
            )
        }
        
        // Check for input-only pins (example for ESP32-C6)
        let inputOnlyPins = [18, 19] // These are typically input-only on some ESP32 variants
        if inputOnlyPins.contains(pinNum) {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "pin",
                value: String(pinNum),
                reason: "Pin \(pinNum) is input-only and cannot be used for output"
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
    
    private func initialState(_ restoreMode: RestoreMode) -> String {
        switch restoreMode {
        case .restoreDefaultOff, .restoreInvertedDefaultOff:
            return "false"
        case .restoreDefaultOn, .restoreInvertedDefaultOn:
            return "true"
        case .alwaysOff:
            return "false"
        case .alwaysOn:
            return "true"
        }
    }
}