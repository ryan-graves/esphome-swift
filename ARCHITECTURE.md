# ESPHome Swift Component Factory Architecture

## Architecture Overview

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
    
    /// Validate configuration with compile-time type safety
    func validate(config: ConfigType) throws
    
    /// Generate code with compile-time type safety
    func generateCode(config: ConfigType, context: CodeGenerationContext) throws -> ComponentCode
}
```

### Registry with Type Erasure

The component registry uses `any ComponentFactory` for storage while maintaining type safety through protocol extension methods that handle the type conversion automatically.

### Board-Specific Pin Validation

```swift
/// Protocol defining hardware constraints for different ESP32 boards
public protocol BoardConstraints {
    var availableGPIOPins: Set<Int> { get }
    var inputOnlyPins: Set<Int> { get }
    var outputCapablePins: Set<Int> { get }
    var pwmCapablePins: Set<Int> { get }
    var adcCapablePins: Set<Int> { get }
    // ... additional constraints
}

/// ESP32-C6 specific constraints
@frozen
public struct ESP32C6Constraints: BoardConstraints {
    public let availableGPIOPins: Set<Int> = Set(0...30)
    public let inputOnlyPins: Set<Int> = [18, 19]
    // ... implement all constraints
}

/// Centralized pin validator
public struct PinValidator {
    private let boardConstraints: BoardConstraints
    
    public init(boardConstraints: BoardConstraints = ESP32C6Constraints()) {
        self.boardConstraints = boardConstraints
    }
    
    public func validatePin(_ pinConfig: PinConfig, requirements: PinRequirements) throws {
        // Shared validation logic
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

### Centralized Validation
- PinValidator handles board-specific constraints for all components
- Shared validation logic prevents duplication across factories
- Clear error messages guide users to valid alternatives

### Secure Code Generation
- Template system automatically escapes values to prevent injection attacks
- Type-safe parameter substitution with validation
- Reusable templates for common ESP32 patterns

### Registry Architecture
- Composite keys allow platform name reuse across component types (sensor.gpio, switch.gpio)
- Type erasure enables heterogeneous storage while preserving compile-time safety
- Protocol extensions provide seamless dynamic dispatch

This architecture balances type safety, performance, and maintainability for embedded Swift development.