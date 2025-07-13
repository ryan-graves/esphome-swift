# ESPHome Swift Component Factory Architecture Design

## Current Issues

1. **Runtime Type Safety**: All factories use unsafe downcasting with `as?`
2. **Code Duplication**: Pin validation logic repeated across factories
3. **Lack of Compile-Time Guarantees**: No enforcement of config/factory compatibility
4. **Hard-Coded Validation**: Board-specific constraints scattered throughout code
5. **Security Concerns**: String interpolation in code generation can lead to injection

## Proposed Architecture

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

### Type Erasure for Registry Storage

```swift
/// Type-erased wrapper for ComponentFactory storage in collections
public struct AnyComponentFactory {
    public let platform: String
    public let componentType: ComponentType
    public let requiredProperties: [String]
    public let optionalProperties: [String]
    
    private let _validate: (ComponentConfig) throws -> Void
    private let _generateCode: (ComponentConfig, CodeGenerationContext) throws -> ComponentCode
    
    /// Initialize with a type-safe factory
    public init<T: ComponentFactory>(_ factory: T) {
        // Store properties
        self.platform = factory.platform
        self.componentType = factory.componentType
        self.requiredProperties = factory.requiredProperties
        self.optionalProperties = factory.optionalProperties
        
        // Create type-safe closures
        self._validate = { config in
            guard let typedConfig = config as? T.ConfigType else {
                throw ComponentValidationError.incompatibleConfiguration(
                    component: factory.platform,
                    reason: "Expected \(T.ConfigType.self) but got \(type(of: config))"
                )
            }
            try factory.validate(config: typedConfig)
        }
        
        self._generateCode = { config, context in
            guard let typedConfig = config as? T.ConfigType else {
                throw ComponentValidationError.incompatibleConfiguration(
                    component: factory.platform,
                    reason: "Expected \(T.ConfigType.self) but got \(type(of: config))"
                )
            }
            return try factory.generateCode(config: typedConfig, context: context)
        }
    }
    
    public func validate(config: ComponentConfig) throws {
        try _validate(config)
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        return try _generateCode(config, context)
    }
}
```

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
/// Safe template value types
@frozen
public enum TemplateValue {
    case string(String)
    case integer(Int)
    case boolean(Bool)
    case identifier(String)
    case pinNumber(Int)
    
    /// Get safely escaped value for C++ code generation
    var safeCppValue: String {
        switch self {
        case .string(let value):
            return escapeForCpp(value)
        case .identifier(let value):
            return sanitizeIdentifier(value)
        // ... safe conversion for each type
        }
    }
}

/// Secure template renderer
public struct SafeCodeTemplate {
    public let templateContent: String
    private let requiredParameters: Set<String>
    
    public func render(with parameters: [String: TemplateValue]) throws -> String {
        // Safe parameter substitution with validation
    }
}
```

## Migration Strategy

### Phase 1: Foundation
1. ✅ Create PinValidator utility
2. ✅ Create secure template system
3. Update ComponentFactory protocol to use associated types
4. Implement type-erased wrapper
5. Update ComponentRegistry to use type-erased factories

### Phase 2: Component Conversion
1. Convert DHT sensor factory (simplest case)
2. Add comprehensive tests for new factory
3. Convert GPIO switch factory
4. Convert remaining factories one by one
5. Ensure all tests pass after each conversion

### Phase 3: Cleanup
1. Remove old validation methods from individual factories
2. Update all factories to use shared PinValidator
3. Add template-based code generation where beneficial
4. Remove any remaining compatibility code

## Benefits

### Compile-Time Safety
- Associated types ensure config/factory compatibility
- No runtime downcasting in factory implementations
- Type errors caught at build time

### Code Reuse
- Shared pin validation across all factories
- Centralized board constraint definitions
- Reusable secure templates

### Security
- Safe code generation with escaped values
- Prevention of injection attacks
- Input validation at template level

### Maintainability
- Clear separation of concerns
- Consistent patterns across all factories
- Easy to add new boards or components

### Performance
- Efficient pin validation with set-based lookups
- Minimal runtime overhead
- Optimized for embedded Swift targets

## Implementation Notes

### Frozen Structs
Use `@frozen` for performance-critical structs in embedded contexts:

```swift
@frozen
public struct ESP32C6Constraints: BoardConstraints { ... }

@frozen
public enum TemplateValue { ... }
```

### Memory Efficiency
- Use value types where possible
- Minimize heap allocations
- Prefer static data for board constraints

### Error Handling
- Provide clear, actionable error messages
- Include context about board-specific limitations
- Guide users toward valid alternatives

This architecture provides a solid foundation for type-safe, secure, and maintainable component factories while following Swift Embedded best practices.