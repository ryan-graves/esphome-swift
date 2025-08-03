# ESPHome Swift - AI Development Guide

This file provides guidance for AI agents (like Claude) working on the ESPHome Swift codebase. It contains architectural insights, development patterns, and project-specific context to enable effective code contributions.

## Project Overview

ESPHome Swift is a pure Swift Embedded firmware generator for ESP32 microcontrollers that replaces the original Python ESPHome. It compiles native Swift code directly to RISC-V ESP32 boards (C3, C6, H2, P4) from YAML configuration files.

### Core Concept
```
YAML Config → Swift Parser → Swift Component Assembly → Swift Embedded Compilation → ESP32 Firmware
```

### Target Users
- IoT developers familiar with ESPHome
- Swift developers interested in embedded systems  
- Home Assistant users wanting type-safe device firmware

## Architecture: Pure Swift Embedded

**Critical Understanding**: ESPHome Swift uses pure Swift Embedded architecture where Swift provides both development-time type safety AND runtime execution on ESP32 microcontrollers.

### Development Flow
```
YAML Config → Swift Parser → Swift Component Assembly → Swift Embedded Compilation → ESP32 Firmware
```

### Why Pure Swift Embedded?

1. **Runtime Type Safety**: Full Swift type safety and memory safety on the microcontroller
2. **Modern Language Features**: Closures, optionals, generics, error handling on embedded hardware
3. **Unified Development**: Single language from configuration to runtime execution
4. **Apple Ecosystem**: Leverage official Swift Embedded support and Matter integration
5. **Memory Safety**: Automatic memory management eliminates entire classes of embedded bugs

### Swift Embedded Component Pattern
Components are implemented as native Swift classes that compile directly to ESP32 firmware:

```swift
// Swift Embedded component (compiles to ESP32)
@main
struct DHTSensor {
    let pin: GPIO
    let model: DHTModel
    
    func setup() {
        pin.setDirection(.input)
        // Initialize I2C communication
    }
    
    func readTemperature() -> Float? {
        // Native Swift I2C communication
        guard let data = pin.readI2C() else { return nil }
        return processTemperatureData(data)
    }
    
    static func main() {
        let sensor = DHTSensor(pin: GPIO.pin4, model: .dht22)
        sensor.setup()
        
        while true {
            if let temp = sensor.readTemperature() {
                print("Temperature: \(temp)°C")
            }
            sleep(seconds: 1)
        }
    }
}
```

## Core Project Principles

These principles guide all development on ESPHome Swift and ensure we deliver a high-quality, user-friendly experience that honors the original ESPHome while leveraging Swift's strengths.

### 1. Swift Excellence Through Best Practices
- Leverage Swift's type safety, optionals, and error handling for robust firmware generation
- Follow established Swift and Embedded Swift patterns and idioms
- Use Swift's expressiveness to make the codebase maintainable and extensible
- Prioritize compile-time safety over runtime flexibility

### 2. ESPHome-Familiar Developer Experience
- Maintain YAML configuration compatibility where sensible
- Use the same component naming conventions (e.g., `platform: dht`, `pin: GPIO4`)
- Provide clear, actionable error messages that guide users to solutions
- Support the same modular, component-based architecture ESPHome users expect
- Enable seamless Home Assistant integration

### 3. Quality-First Development Workflow
- All code must pass SwiftLint and SwiftFormat checks before commit
- Every component requires comprehensive unit tests
- Validate YAML configurations thoroughly at parse time
- Run `swift test` successfully before any PR submission
- Generate ESP-IDF code that compiles without warnings

### 4. User-Centric Design Philosophy
- "No C++ coding required" - users work only with YAML
- Provide sensible defaults while allowing full customization
- Support Over-The-Air (OTA) updates for deployed devices
- Prioritize local control and privacy (no cloud dependencies)
- Make error messages educational, not just diagnostic

### 5. Hardware-Aware Implementation
- Validate all pin assignments against actual board capabilities
- Provide board-specific constraints and features dynamically
- Generate efficient code appropriate for resource-constrained devices
- Support the ESP32 RISC-V family (C3, C6, H2, P4) as first-class citizens

## Architecture Overview

### Module Structure
```
ESPHomeSwift/
├── Sources/
│   ├── ESPHomeSwiftCore/     # Core configuration parsing & validation
│   ├── SwiftEmbeddedGen/     # Swift → Swift Embedded compilation
│   ├── ComponentLibrary/     # Swift Embedded component implementations
│   ├── CLI/                  # Command-line interface (ArgumentParser)
│   └── WebDashboard/         # Web-based monitoring (Vapor.js)
├── Tests/                    # Unit tests for each module
├── Examples/                 # Sample YAML configurations
└── Resources/                # Code templates and schemas
```

### Key Design Patterns

#### 1. **Component Factory Pattern**
All sensors, switches, lights, etc. implement `ComponentFactory`:
```swift
public protocol ComponentFactory {
    var platform: String { get }
    var componentType: ComponentType { get }
    var requiredProperties: [String] { get }
    var optionalProperties: [String] { get }
    
    func validate(config: ComponentConfig) throws
    func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode
}
```

#### 2. **Configuration as Code**
YAML configurations are parsed into strongly-typed Swift structs with `Codable` conformance.

#### 3. **Native Swift Component Assembly**
Components are assembled into a complete Swift Embedded application using native Swift composition and dependency injection.

## Development Guidelines for AI Agents

### When Adding New Components

1. **Identify the component type** (sensor, switch, light, binary_sensor)
2. **Create factory class** in appropriate directory:
   - `Sources/ComponentLibrary/Sensors/` for sensors
   - `Sources/ComponentLibrary/Switches/` for switches
   - `Sources/ComponentLibrary/Lights/` for lights
   - etc.

3. **Follow naming convention**: `{Name}{Type}Factory` (e.g., `BME280SensorFactory`)

4. **Implement validation**:
   - Check required properties exist
   - Validate pin numbers for ESP32-C6 constraints
   - Verify platform-specific requirements

5. **Implement Swift Embedded component**:
   - Create native Swift class with hardware abstractions
   - Implement setup() method for component initialization
   - Implement runtime methods for ongoing operation
   - Use Swift error handling and type safety

6. **Register in ComponentLibrary.swift**:
   ```swift
   private func registerBuiltInComponents() {
       // existing components...
       register(NewSensorFactory())
   }
   ```

7. **Add tests** in corresponding `Tests/ComponentLibraryTests/` file

### Swift Embedded Component Patterns

#### Common Swift Embedded Structure
```swift
// Native Swift hardware abstraction
import SwiftEmbedded
import ESP32Hardware

struct GPIOSensor {
    let pin: GPIO
    
    init(pin: GPIO) {
        self.pin = pin
    }
    
    func setup() throws {
        try pin.setDirection(.input)
    }
    
    func readValue() -> Bool {
        return pin.digitalRead()
    }
}
```

#### Board-Aware Pin Validation
```swift
// IMPORTANT: Components should use board-specific validation (Core Principle #5)
public func validate(config: ConfigType, board: String) throws {
    // Validate required properties first
    guard let pin = config.pin else {
        throw ComponentValidationError.missingRequiredProperty(
            component: platform,
            property: "pin"
        )
    }
    
    // Use shared helper for consistent board validation (eliminates boilerplate)
    // This will throw ComponentValidationError.invalidPropertyValue if board is unsupported
    let pinValidator = try createPinValidator(for: board)
    
    // Board-specific pin validation with appropriate requirements
    try pinValidator.validatePin(pin, requirements: .output)
    
    // Example: Additional board-specific validation
    if board.contains("esp32-h2") && someH2SpecificFeature {
        // Handle H2-specific constraints
        throw ComponentValidationError.invalidPropertyValue(
            component: platform,
            property: "feature", 
            value: "not_supported_on_h2",
            reason: "This feature is not available on ESP32-H2 boards"
        )
    }
}

// Example: Swift component creation with board context
public func createComponent(config: ConfigType, context: SwiftEmbeddedContext) throws -> any SwiftComponent {
    // Use shared helper for board definition extraction
    let boardDef = try getBoardDefinition(from: context)
    let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
    
    // Create native Swift component instance
    return try GPIOSensor(pin: GPIO(config.pin, board: boardDef))
}
```

### Configuration Parsing

#### YAML to Swift Mapping
- Use `CodingKeys` for snake_case → camelCase conversion
- Optional properties should be `Optional` types
- Validate at parse time, not generation time

#### Example Configuration Structure
```swift
public struct SensorConfig: Codable {
    public let platform: String
    public let pin: PinConfig
    public let name: String?
    public let updateInterval: String?
    
    enum CodingKeys: String, CodingKey {
        case platform
        case pin
        case name
        case updateInterval = "update_interval"
    }
}
```

### Testing Strategy

#### Unit Tests
- Test factory creation and validation
- Test code generation with known inputs
- Test error conditions and edge cases

#### Integration Tests  
- Validate complete YAML configurations
- Test CLI commands end-to-end
- Verify Swift Embedded compilation and hardware testing

#### Example Test Pattern
```swift
func testDHTSensorValidation() throws {
    let factory = DHTSensorFactory()
    let config = ComponentConfig(
        platform: "dht",
        properties: [
            "pin": .string("GPIO4"),
            "model": .string("DHT22")
        ]
    )
    
    XCTAssertNoThrow(try factory.validate(config: config))
}
```

### Common Pitfalls to Avoid

1. **Pin Configuration**: Always validate against board-specific constraints (not hardcoded to one board)
2. **String Interpolation**: Escape backslashes properly in generated code  
3. **Optional Chaining**: Use safe unwrapping for optional configuration values
4. **Error Messages**: Provide clear, actionable error messages for users (Core Principle #4)
5. **Thread Safety**: ESP-IDF code should be thread-aware (FreeRTOS)
6. **Board Assumptions**: Never hardcode board-specific behavior; use BoardCapabilities instead

### ESP32-C6 Hardware Constraints

#### GPIO Limitations
- **Total pins**: GPIO0-GPIO30 (not all usable)
- **Input-only**: GPIO18, GPIO19
- **ADC pins**: GPIO0-GPIO7 (ADC1 only)
- **PWM capable**: Most GPIO pins except input-only
- **I2C default**: SDA=GPIO5, SCL=GPIO6
- **SPI default**: MOSI=GPIO7, MISO=GPIO2, CLK=GPIO6, CS=GPIO10

#### Power and Timing
- **Operating voltage**: 3.3V
- **ADC resolution**: 12-bit (0-4095)
- **PWM frequency**: Typically 1kHz-20kHz
- **FreeRTOS**: Task-based, avoid blocking operations in loop

### Code Quality Standards

#### Swift Conventions
- Use `camelCase` for variables and functions
- Use `PascalCase` for types and protocols
- Follow SwiftLint rules (configured in `.swiftlint.yml`)
- Use SwiftFormat for consistent formatting

#### Swift Embedded Code Conventions
- Use Swift naming conventions (camelCase, PascalCase)
- Add Swift documentation comments for all public APIs
- Leverage Swift's error handling and Optional types
- Follow Swift Embedded patterns and memory management

### Branching Workflow for AI

ESPHome Swift uses a Git Flow inspired branching strategy following CONTRIBUTING.md:

1. **Always start from develop**:
   ```bash
   git checkout develop
   git pull upstream develop  # or origin develop
   git checkout -b feature/descriptive-name
   ```

2. **Branch naming conventions**:
   - `feature/add-i2c-sensor-support`
   - `fix/dht-timeout-issue`
   - `docs/update-component-examples`
   - Use kebab-case (lowercase with hyphens)

3. **Create PR targeting develop** (NEVER main)

4. **Follow conventional commits**:
   - `feat:` for new components/features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for code refactoring
   - `test:` for tests
   - `chore:` for maintenance tasks

5. **Ensure CI passes**:
   - SwiftLint validation (macOS only)
   - SwiftFormat checking (cross-platform)
   - All tests pass
   - Cross-platform builds succeed

6. **MANDATORY: Run all status checks before pushing**:
   ```bash
   # Always run these commands before git push
   swift test                    # Ensure all tests pass
   swiftlint                    # Check for linting violations  
   swiftformat --lint .         # Check formatting compliance
   swift build                  # Ensure clean build
   
   # If swiftformat --lint finds issues, fix them with:
   swiftformat .                # Auto-format all Swift files
   ```
   
   **Critical**: Never push code that fails any of these checks. GitHub CI will fail and block the PR. Fix all issues locally first. SwiftFormat is particularly strict and will cause CI failures if not run.

### Useful Development Commands

```bash
# Build project
swift build

# Run tests
swift test

# Run CLI locally
swift run esphome-swift --help

# Check code quality
swiftlint
swiftformat --lint .

# Validate example configurations
swift run esphome-swift validate Examples/basic-sensor.yaml

# Compile Swift Embedded firmware
swift run esphome-swift build Examples/basic-sensor.yaml
```

### Common File Locations

- **Add new component**: `Sources/ComponentLibrary/{ComponentType}/`
- **Update CLI**: `Sources/CLI/CLI.swift`
- **Core config types**: `Sources/ESPHomeSwiftCore/Configuration.swift`
- **Component registration**: `Sources/ComponentLibrary/ComponentLibrary.swift`
- **Tests**: `Tests/{ModuleName}Tests/`
- **Examples**: `Examples/`

### References

- **ESPHome Documentation**: https://esphome.io/
- **ESP-IDF Documentation**: https://docs.espressif.com/projects/esp-idf/
- **ESP32-C6 Datasheet**: For pin layouts and hardware specs
- **Swift Package Manager**: https://swift.org/package-manager/
- **Embedded Swift**: https://github.com/apple/swift-embedded-examples

### Swift Embedded Migration Status

**CURRENT PRIORITY: Complete migration to Swift Embedded architecture**

ESPHome Swift is undergoing a complete architectural migration from C++ code generation to pure Swift Embedded compilation. This migration eliminates the need for Arduino-style libraries and provides true runtime type safety.

**Migration Philosophy**:
- **Quality over speed**: Take time to understand each problem deeply and implement correct solutions
- **No shortcuts**: Build the foundation that will support ESPHome Swift for years to come
- **Complete solutions**: No temporary fixes or half-measures during migration
- **Cross-platform support**: Ensure Linux development environment works throughout

**Current Status**: Phase 0 - Foundation setup and documentation updates
**Branch Strategy**: Use feature branches for each migration phase
**Logging**: Maintain comprehensive logs in `docs/swift-embedded-migration/`

### Development Philosophy for AI Agents

**Take Time to Do Things Right**: This project prioritizes architectural correctness and code quality over development speed. There is no rush. Do everything the correct way, even if it's more complex.

**Alignment with Core Principles**: All development work must align with the Core Project Principles defined above. When making decisions, refer back to these principles to ensure consistency across the codebase.

**Swift Embedded First Guidelines**:
1. **Pure Swift Approach**: No more C++ code generation - everything compiles to native Swift Embedded
2. **No Legacy Compatibility**: Since no users exist, optimize purely for Swift Embedded without backward compatibility
3. **Runtime Safety**: Leverage Swift's memory safety, type safety, and error handling on embedded hardware
4. **Apple Ecosystem**: Use official Swift Embedded patterns and Matter protocol integration
5. **Cross-Platform Development**: Ensure Linux developers have full capability alongside macOS

**Key Implementation Guidelines**:
1. **No Shortcuts**: Don't rush refactoring or take shortcuts that compromise code quality
2. **Best Practices First**: Always follow Swift Embedded and general Swift best practices (see Core Principle #1)
3. **Type Safety**: Prefer compile-time safety over runtime convenience
4. **Clean Architecture**: Maintain clear separation of concerns and avoid tight coupling
5. **Future-Proof**: Design with extensibility and maintainability in mind
6. **Test-Driven**: Ensure all changes are covered by tests and don't break existing functionality (see Core Principle #3)
7. **ESPHome Compatibility**: Maintain familiar patterns and conventions for ESPHome users (see Core Principle #2)
8. **CRITICAL: Pre-Push Validation**: Always run `swift test`, `swiftlint`, `swiftformat --lint .`, and `swift build` before pushing. Never push failing code. If SwiftFormat finds issues, run `swiftformat .` to fix them.

**When Implementing Swift Embedded Components**:
- Research Swift Embedded examples and patterns thoroughly before implementing
- Use native Swift hardware abstractions instead of C/C++ bindings
- Implement proper Swift error handling for all hardware operations
- Test components on actual ESP32 hardware, not just compilation
- Document Swift-specific patterns for future component developers
- Ensure all components work cross-platform (macOS and Linux development)

**When Refactoring**:
- Complete each architectural change thoroughly before moving to the next
- Ensure all components work together after each major change
- Don't leave half-converted code or compatibility layers permanently
- Fix all compilation errors and test failures before proceeding
- Document architectural decisions and patterns for future developers
- Update all documentation to reflect Swift Embedded patterns

### Getting Help

When encountering issues:
1. Check existing component implementations for patterns
2. Review test files for usage examples  
3. Consult ESP-IDF documentation for hardware specifics
4. Test with physical ESP32-C6 hardware when possible
5. **When in doubt, prioritize correctness over speed**

---

**Last Updated**: July 2025 - Swift Embedded Migration  
**For**: AI Development Assistance  
**Scope**: ESPHome Swift v0.2.0+ (Swift Embedded Architecture)