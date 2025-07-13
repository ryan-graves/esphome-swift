import Foundation
import ESPHomeSwiftCore

/// GPIO-based binary sensor factory
public struct GPIOBinarySensorFactory: ComponentFactory {
    public typealias ConfigType = BinarySensorConfig
    
    public let platform = "gpio_binary" // Unique platform name to avoid conflicts
    public let componentType = ComponentType.binarySensor
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "device_class", "inverted", "filters"]
    
    private let pinValidator: PinValidator
    
    public init(pinValidator: PinValidator = PinValidator()) {
        self.pinValidator = pinValidator
    }
    
    public func validate(config: BinarySensorConfig) throws {
        // Validate required pin
        guard let pin = config.pin else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Use shared pin validator with input requirements
        try pinValidator.validatePin(pin, requirements: .input)
    }
    
    public func generateCode(config: BinarySensorConfig, context: CodeGenerationContext) throws -> ComponentCode {
        let pinNumber = try pinValidator.extractPinNumber(from: config.pin!)
        let componentId = config.id ?? "binary_sensor_\(pinNumber)"
        let inverted = config.inverted ?? false
        let pullMode = determinePullMode(config.pin!)
        
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
                    
                    printf("\(config.name ?? componentId): %s\\n", \(componentId)_current_state ? "ON" : "OFF");
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