# ESPHome Swift - AI Development Guide

This file provides guidance for AI agents (like Claude) working on the ESPHome Swift codebase. It contains architectural insights, development patterns, and project-specific context to enable effective code contributions.

## Project Overview

ESPHome Swift is a Swift-based firmware generator for ESP32 microcontrollers that replaces the original Python ESPHome. It generates Embedded Swift code for RISC-V ESP32 boards (C3, C6, H2, P4) from YAML configuration files.

### Core Concept
```
YAML Config → Swift Parser → Code Generation → ESP-IDF/Embedded Swift → ESP32 Firmware
```

### Target Users
- IoT developers familiar with ESPHome
- Swift developers interested in embedded systems  
- Home Assistant users wanting type-safe device firmware

## Architecture Overview

### Module Structure
```
ESPHomeSwift/
├── Sources/
│   ├── ESPHomeSwiftCore/     # Core configuration parsing & validation
│   ├── CodeGeneration/       # Swift → ESP-IDF code generation
│   ├── ComponentLibrary/     # Built-in component definitions
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

#### 3. **Template-Based Code Generation**
Generated code uses string interpolation and templates to create valid ESP-IDF/Embedded Swift code.

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

5. **Generate appropriate code**:
   - Include necessary headers
   - Add global declarations
   - Provide setup code (runs once)
   - Provide loop code (runs repeatedly)

6. **Register in ComponentLibrary.swift**:
   ```swift
   private func registerBuiltInComponents() {
       // existing components...
       register(NewSensorFactory())
   }
   ```

7. **Add tests** in corresponding `Tests/ComponentLibraryTests/` file

### Code Generation Patterns

#### Common ESP-IDF Structure
```cpp
// Headers
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"

// Global declarations
static gpio_num_t sensor_pin = GPIO_NUM_4;

// Setup code (in setup() function)
gpio_set_direction(sensor_pin, GPIO_MODE_INPUT);

// Loop code (in loop() function)  
int value = gpio_get_level(sensor_pin);
```

#### Pin Validation for ESP32-C6
```swift
private func validatePin(_ pinNumber: String) throws {
    guard let pin = extractGPIONumber(pinNumber) else {
        throw ValidationError.invalidPin("Invalid GPIO format: \(pinNumber)")
    }
    
    // ESP32-C6 constraints
    if pin < 0 || pin > 30 {
        throw ValidationError.invalidPin("GPIO\(pin) not available on ESP32-C6")
    }
    
    // Input-only pins
    if [18, 19].contains(pin) && requiresOutput {
        throw ValidationError.invalidPin("GPIO\(pin) is input-only")
    }
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
- Verify generated code compiles (if ESP-IDF available)

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

1. **Pin Configuration**: Always validate against ESP32-C6 specific constraints
2. **String Interpolation**: Escape backslashes properly in generated code  
3. **Optional Chaining**: Use safe unwrapping for optional configuration values
4. **Error Messages**: Provide clear, actionable error messages for users
5. **Thread Safety**: ESP-IDF code should be thread-aware (FreeRTOS)

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

#### Generated Code Conventions
- Use C naming conventions for ESP-IDF compatibility
- Add comments explaining generated sections
- Include error handling and safety checks
- Follow ESP-IDF component structure

### Branching Workflow for AI

When making changes:

1. **Always start from develop**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/descriptive-name
   ```

2. **Create PR targeting develop** (never main)

3. **Follow conventional commits**:
   - `feat:` for new components/features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `test:` for tests

4. **Ensure CI passes**:
   - SwiftLint validation
   - SwiftFormat checking
   - All tests pass
   - Cross-platform builds succeed

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

### Getting Help

When encountering issues:
1. Check existing component implementations for patterns
2. Review test files for usage examples  
3. Consult ESP-IDF documentation for hardware specifics
4. Test with physical ESP32-C6 hardware when possible

---

**Last Updated**: January 2025  
**For**: AI Development Assistance  
**Scope**: ESPHome Swift v0.1.0+