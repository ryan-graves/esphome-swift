import Foundation
import ESPHomeSwiftCore

/// RGB light factory
public struct RGBLightFactory: ComponentFactory {
    public typealias ConfigType = LightConfig
    
    public let platform = "rgb"
    public let componentType = ComponentType.light
    public let requiredProperties = ["red_pin", "green_pin", "blue_pin"]
    public let optionalProperties = ["name", "effects"]
    
    public init() {}
    
    public func validate(config: LightConfig, board: String) throws {
        guard let redPin = config.redPin else {
            throw ComponentValidationError.missingRequiredProperty(component: platform, property: "red_pin")
        }
        guard let greenPin = config.greenPin else {
            throw ComponentValidationError.missingRequiredProperty(component: platform, property: "green_pin")
        }
        guard let bluePin = config.bluePin else {
            throw ComponentValidationError.missingRequiredProperty(component: platform, property: "blue_pin")
        }
        
        let pinValidator = try createPinValidator(for: board)
        try pinValidator.validatePin(redPin, requirements: .pwm)
        try pinValidator.validatePin(greenPin, requirements: .pwm)
        try pinValidator.validatePin(bluePin, requirements: .pwm)
    }
    
    public func generateCode(config: LightConfig, context: CodeGenerationContext) throws -> ComponentCode {
        let boardDef = try getBoardDefinition(from: context)
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        let redPin = try pinValidator.extractPinNumber(from: config.redPin!)
        let greenPin = try pinValidator.extractPinNumber(from: config.greenPin!)
        let bluePin = try pinValidator.extractPinNumber(from: config.bluePin!)
        let componentId = config.id ?? "rgb_light"
        
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
                
                printf("\(config.name ?? componentId): RGB(%d, %d, %d)\\n", red, green, blue);
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
}