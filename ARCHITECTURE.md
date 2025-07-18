# ESPHome Swift Architecture

## High-Level Architecture

ESPHome Swift uses a **hybrid architecture** combining Swift's type safety for development with C/C++ reliability for embedded execution.

### Development vs Runtime Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEVELOPMENT TIME (Swift)                    │
├─────────────────────────────────────────────────────────────────┤
│ YAML Config → Swift Parser → Validation → Code Generation      │
│                                                                 │
│ • Type-safe configuration parsing                               │
│ • Board-aware validation                                        │
│ • Component factory system                                      │
│ • C/C++ code generation                                         │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     RUNTIME (C/C++ on ESP32)                   │
├─────────────────────────────────────────────────────────────────┤
│ Generated C++ → ESP-IDF Build → ESP32 Firmware                 │
│                                                                 │
│ • Native ESP32 performance                                      │
│ • Direct hardware access                                        │
│ • Home Assistant API server                                     │
│ • Matter protocol support                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Hybrid Approach?

1. **Development Benefits (Swift)**:
   - Type safety prevents configuration errors
   - Rich error messages and debugging
   - Modern tooling and IDE support
   - Powerful code generation capabilities

2. **Runtime Benefits (C/C++)**:
   - Native ESP32 performance
   - Minimal memory footprint
   - Proven ESP-IDF ecosystem
   - Direct hardware peripheral access

3. **Future Compatibility**:
   - Ready for Swift Embedded when ESP32 support matures
   - Can offer both approaches simultaneously
   - Maintains ESPHome ecosystem compatibility

## Component Factory Architecture

ESPHome Swift uses a type-safe component factory system with compile-time guarantees and centralized validation utilities.

### Type-Safe Component Factory Protocol

```swift
/// Type-safe protocol for component factories
public protocol ComponentFactory {
    /// Associated type that defines the specific configuration this factory accepts
    associatedtype ConfigType: ComponentConfig
    
    /// Platform identifier (e.g., "dht", "gpio")
    var platform: String { get }
    
    /// Component type classification
    var componentType: ComponentType { get }
    
    /// Required configuration properties
    var requiredProperties: [String] { get }
    
    /// Optional configuration properties  
    var optionalProperties: [String] { get }
    
    /// Validate configuration with board-specific constraints
    func validate(config: ConfigType, board: String) throws
    
    /// Generate code with compile-time type safety
    func generateCode(config: ConfigType, context: CodeGenerationContext) throws -> ComponentCode
}
```

### Registry with Type Erasure

The component registry uses `any ComponentFactory` for storage while maintaining type safety through protocol extension methods that handle the type conversion automatically.

### Board Capabilities System

```swift
/// Board capabilities provide hardware-specific constraints and features
public struct BoardCapabilities {
    /// Get board definition for validation and code generation
    public static func boardDefinition(for board: String) -> BoardDefinition? {
        // Resolve board identifier and return capabilities
    }
    
    /// Query board capability support
    public static func boardSupports(_ board: String, capability: BoardCapability) -> Bool {
        // Check if board supports WiFi, Thread, Matter, etc.
    }
}

/// Board-specific hardware constraints
public protocol BoardConstraints {
    var availableGPIOPins: Set<Int> { get }
    var inputOnlyPins: Set<Int> { get }
    var outputCapablePins: Set<Int> { get }
    var pwmCapablePins: Set<Int> { get }
    var adcCapablePins: Set<Int> { get }
    var i2cDefaultSDA: Int { get }
    var i2cDefaultSCL: Int { get }
    var spiDefaultMOSI: Int { get }
    var spiDefaultMISO: Int { get }
    var spiDefaultCLK: Int { get }
    var spiDefaultCS: Int { get }
}

/// Pin validator with board-specific constraints
public struct PinValidator {
    private let boardConstraints: BoardConstraints
    
    public init(boardConstraints: BoardConstraints) {
        self.boardConstraints = boardConstraints
    }
    
    public func validatePin(_ pinConfig: PinConfig, requirements: PinRequirements) throws {
        // Validate against board-specific constraints
    }
}
```

### Secure Code Generation Templates

```swift
/// Template value types with automatic escaping
@frozen
public enum TemplateValue {
    case string(String)
    case integer(Int)
    case boolean(Bool)
    case identifier(String)
    case pinNumber(Int)
    
    /// Get escaped value for C++ code generation
    var cppValue: String {
        switch self {
        case .string(let value):
            return escapeForCpp(value)
        case .identifier(let value):
            return sanitizeIdentifier(value)
        // ... safe conversion for each type
        }
    }
}
```

## Key Design Decisions

### Type Safety with Performance
- Associated types provide compile-time guarantees for config/factory compatibility
- `@frozen` structs minimize runtime overhead in embedded contexts
- Value types reduce heap allocations

### Board-Aware Validation
- BoardCapabilities system provides hardware constraints for all ESP32 variants
- PinValidator enforces board-specific limitations during configuration parsing
- Components validate pin assignments against target board capabilities
- Clear error messages guide users to valid alternatives for their hardware

### Secure Code Generation
- Template system automatically escapes values to prevent injection attacks
- Type-safe parameter substitution with validation
- Reusable templates for common ESP32 patterns

### Registry Architecture
- Composite keys allow platform name reuse across component types (sensor.gpio, switch.gpio)
- Type erasure enables heterogeneous storage while preserving compile-time safety
- Protocol extensions provide seamless dynamic dispatch

### Example Component Implementation

```swift
public struct GPIOSwitchFactory: ComponentFactory {
    public typealias ConfigType = SwitchConfig
    
    public let platform = "gpio"
    public let componentType = ComponentType.switch_
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "inverted", "restore_mode"]
    
    public func validate(config: SwitchConfig, board: String) throws {
        guard let pin = config.pin else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform, property: "pin"
            )
        }
        
        // Validate pin against board capabilities
        guard let boardDef = BoardCapabilities.boardDefinition(for: board) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform, property: "board", value: board,
                reason: "Unsupported board"
            )
        }
        
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        try pinValidator.validatePin(pin, requirements: .output)
    }
    
    public func generateCode(config: SwitchConfig, context: CodeGenerationContext) throws -> ComponentCode {
        // Code generation uses board-specific context
        let boardDef = BoardCapabilities.boardDefinition(for: context.targetBoard)!
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        let pinNumber = try pinValidator.extractPinNumber(from: config.pin!)
        
        return ComponentCode(
            headerIncludes: ["#include \"driver/gpio.h\""],
            globalDeclarations: ["bool switch_\(pinNumber)_state = false;"],
            setupCode: ["gpio_set_direction(GPIO_NUM_\(pinNumber), GPIO_MODE_OUTPUT);"],
            classDefinitions: ["void switch_\(pinNumber)_toggle() { /* ... */ }"]
        )
    }
}
```

This architecture balances type safety, performance, and maintainability for embedded Swift development across multiple ESP32 board variants.