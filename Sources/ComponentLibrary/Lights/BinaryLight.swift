import Foundation
import ESPHomeSwiftCore

/// Binary (on/off) light factory
public class BinaryLightFactory: ComponentFactory {
    public let platform = "binary"
    public let componentType = ComponentType.light
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name"]
    
    public func validate(config: ComponentConfig) throws {
        guard let lightConfig = config as? LightConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected LightConfig"
            )
        }
        
        // Validate required pin
        guard lightConfig.pin != nil else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Validate pin is output-capable
        if let pin = lightConfig.pin {
            try validateOutputPin(pin)
        }
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        guard let lightConfig = config as? LightConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected LightConfig"
            )
        }
        
        let pinNumber = extractPinNumber(lightConfig.pin!)
        let componentId = lightConfig.id ?? "binary_light_\(pinNumber)"
        
        let headerIncludes = [
            "#include \"driver/gpio.h\""
        ]
        
        let globalDeclarations = [
            "bool \(componentId)_state = false;"
        ]
        
        let setupCode = [
            "gpio_config_t \(componentId)_config = {};",
            "\(componentId)_config.pin_bit_mask = (1ULL << \(pinNumber));",
            "\(componentId)_config.mode = GPIO_MODE_OUTPUT;",
            "\(componentId)_config.pull_up_en = GPIO_PULLUP_DISABLE;",
            "\(componentId)_config.pull_down_en = GPIO_PULLDOWN_DISABLE;",
            "\(componentId)_config.intr_type = GPIO_INTR_DISABLE;",
            "gpio_config(&\(componentId)_config);",
            "gpio_set_level(GPIO_NUM_\(pinNumber), 0);"
        ]
        
        let classDefinitions = [
            """
            void \(componentId)_turn_on() {
                \(componentId)_state = true;
                gpio_set_level(GPIO_NUM_\(pinNumber), 1);
                Serial.println("\(lightConfig.name ?? componentId): ON");
                // TODO: Send state via API
            }
            
            void \(componentId)_turn_off() {
                \(componentId)_state = false;
                gpio_set_level(GPIO_NUM_\(pinNumber), 0);
                Serial.println("\(lightConfig.name ?? componentId): OFF");
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
            let number = gpio.replacingOccurrences(of: "GPIO", with: "")
            return Int(number) ?? 0
        }
    }
}

/// RGB light factory
public class RGBLightFactory: ComponentFactory {
    public let platform = "rgb"
    public let componentType = ComponentType.light
    public let requiredProperties = ["red_pin", "green_pin", "blue_pin"]
    public let optionalProperties = ["name", "white_pin"]
    
    public func validate(config: ComponentConfig) throws {
        guard let lightConfig = config as? LightConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected LightConfig"
            )
        }
        
        // Validate required pins
        guard lightConfig.redPin != nil else {
            throw ComponentValidationError.missingRequiredProperty(component: platform, property: "red_pin")
        }
        guard lightConfig.greenPin != nil else {
            throw ComponentValidationError.missingRequiredProperty(component: platform, property: "green_pin")
        }
        guard lightConfig.bluePin != nil else {
            throw ComponentValidationError.missingRequiredProperty(component: platform, property: "blue_pin")
        }
        
        // Validate all pins are PWM-capable
        try validatePWMPin(lightConfig.redPin!, color: "red")
        try validatePWMPin(lightConfig.greenPin!, color: "green")
        try validatePWMPin(lightConfig.bluePin!, color: "blue")
        
        if let whitePin = lightConfig.whitePin {
            try validatePWMPin(whitePin, color: "white")
        }
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        guard let lightConfig = config as? LightConfig else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected LightConfig"
            )
        }
        
        let redPin = extractPinNumber(lightConfig.redPin!)
        let greenPin = extractPinNumber(lightConfig.greenPin!)
        let bluePin = extractPinNumber(lightConfig.bluePin!)
        let componentId = lightConfig.id ?? "rgb_light"
        
        let headerIncludes = [
            "#include \"driver/ledc.h\""
        ]
        
        let globalDeclarations = [
            "uint8_t \(componentId)_red = 0;",
            "uint8_t \(componentId)_green = 0;",
            "uint8_t \(componentId)_blue = 0;",
            "bool \(componentId)_state = false;"
        ]
        
        let setupCode = [
            "// Setup PWM for RGB light",
            "ledc_timer_config_t \(componentId)_timer = {",
            "    .speed_mode = LEDC_LOW_SPEED_MODE,",
            "    .timer_num = LEDC_TIMER_0,",
            "    .duty_resolution = LEDC_TIMER_8_BIT,",
            "    .freq_hz = 1000,",
            "    .clk_cfg = LEDC_AUTO_CLK",
            "};",
            "ledc_timer_config(&\(componentId)_timer);",
            "",
            "// Red channel",
            "ledc_channel_config_t \(componentId)_red_channel = {",
            "    .speed_mode = LEDC_LOW_SPEED_MODE,",
            "    .channel = LEDC_CHANNEL_0,",
            "    .timer_sel = LEDC_TIMER_0,",
            "    .intr_type = LEDC_INTR_DISABLE,",
            "    .gpio_num = \(redPin),",
            "    .duty = 0,",
            "    .hpoint = 0",
            "};",
            "ledc_channel_config(&\(componentId)_red_channel);",
            "",
            "// Green channel",
            "ledc_channel_config_t \(componentId)_green_channel = {",
            "    .speed_mode = LEDC_LOW_SPEED_MODE,",
            "    .channel = LEDC_CHANNEL_1,",
            "    .timer_sel = LEDC_TIMER_0,",
            "    .intr_type = LEDC_INTR_DISABLE,",
            "    .gpio_num = \(greenPin),",
            "    .duty = 0,",
            "    .hpoint = 0",
            "};",
            "ledc_channel_config(&\(componentId)_green_channel);",
            "",
            "// Blue channel",
            "ledc_channel_config_t \(componentId)_blue_channel = {",
            "    .speed_mode = LEDC_LOW_SPEED_MODE,",
            "    .channel = LEDC_CHANNEL_2,",
            "    .timer_sel = LEDC_TIMER_0,",
            "    .intr_type = LEDC_INTR_DISABLE,",
            "    .gpio_num = \(bluePin),",
            "    .duty = 0,",
            "    .hpoint = 0",
            "};",
            "ledc_channel_config(&\(componentId)_blue_channel);"
        ]
        
        let classDefinitions = [
            """
            void \(componentId)_set_rgb(uint8_t red, uint8_t green, uint8_t blue) {
                \(componentId)_red = red;
                \(componentId)_green = green;
                \(componentId)_blue = blue;
                \(componentId)_state = (red > 0 || green > 0 || blue > 0);
                
                ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_0, red);
                ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_0);
                
                ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1, green);
                ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1);
                
                ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_2, blue);
                ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_2);
                
                Serial.printf("\(lightConfig.name ?? componentId): RGB(%d, %d, %d)\\n", red, green, blue);
                // TODO: Send state via API
            }
            
            void \(componentId)_turn_on() {
                \(componentId)_set_rgb(255, 255, 255);
            }
            
            void \(componentId)_turn_off() {
                \(componentId)_set_rgb(0, 0, 0);
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
    
    private func validatePWMPin(_ pin: PinConfig, color: String) throws {
        let pinNum = extractPinNumber(pin)
        
        if pinNum < 0 || pinNum > 48 {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "\(color)_pin",
                value: String(pinNum),
                reason: "GPIO pin must be between 0 and 48"
            )
        }
        
        // PWM pins should support LEDC on ESP32-C6
        // Most GPIO pins support PWM, but some are input-only
        let inputOnlyPins = [18, 19]
        if inputOnlyPins.contains(pinNum) {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "\(color)_pin",
                value: String(pinNum),
                reason: "Pin \(pinNum) is input-only and cannot be used for PWM output"
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
}