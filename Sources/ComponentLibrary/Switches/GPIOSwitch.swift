import Foundation
import ESPHomeSwiftCore

/// GPIO-based switch factory
public struct GPIOSwitchFactory: ComponentFactory {
    public typealias ConfigType = SwitchConfig
    
    public let platform = "gpio"
    public let componentType = ComponentType.switch_
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "inverted", "restore_mode"]
    
    public init() {
        // No longer store pinValidator as instance variable - create board-specific validator per call
    }
    
    public func validate(config: SwitchConfig, board: String) throws {
        // Validate required pin
        guard let pin = config.pin else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Create board-specific pin validator
        guard let boardDef = BoardCapabilities.boardDefinition(for: board) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "board",
                value: board,
                reason: "Unsupported board. Use 'swift run esphome-swift boards' to see available boards."
            )
        }
        
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        try pinValidator.validatePin(pin, requirements: .output)
    }
    
    public func generateCode(config: SwitchConfig, context: CodeGenerationContext) throws -> ComponentCode {
        // Create board-specific pin validator for code generation
        guard let boardDef = BoardCapabilities.boardDefinition(for: context.targetBoard) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "board",
                value: context.targetBoard,
                reason: "Unsupported board"
            )
        }
        
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        let pinNumber = try pinValidator.extractPinNumber(from: config.pin!)
        let componentId = config.id ?? "gpio_switch_\(pinNumber)"
        let inverted = config.inverted ?? false
        let restoreMode = config.restoreMode ?? .restoreDefaultOff
        
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
                printf("\(config.name ?? componentId): ON\\n");
                // TODO: Send state via API
            }
            
            void \(componentId)_turn_off() {
                \(componentId)_state = false;
                gpio_set_level(GPIO_NUM_\(pinNumber), \(inverted ? "1" : "0"));
                printf("\(config.name ?? componentId): OFF\\n");
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