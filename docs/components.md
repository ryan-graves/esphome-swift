---
layout: default
title: Component Library
---

# Component Library

ESPHome Swift includes a growing library of components for various sensors, actuators, and integrations. This page documents all available components and how to use them.

## Sensor Components

Sensors are input devices that read values from the physical world.

### DHT Temperature & Humidity

The DHT component supports DHT11, DHT22, and AM2302 temperature and humidity sensors.

```yaml
sensor:
  - platform: dht
    pin:
      number: GPIO4
    model: DHT22              # DHT11, DHT22, or AM2302
    temperature:
      name: "Room Temperature"
    humidity:
      name: "Room Humidity"
    update_interval: 60s      # How often to read
```

**Wiring:**
- VCC → 3.3V
- GND → GND
- DATA → GPIO pin (with 10kΩ pullup resistor)

**Notes:**
- DHT sensors are slow (2s read time)
- Not suitable for rapid polling
- DHT11: ±2°C, ±5% RH
- DHT22: ±0.5°C, ±2% RH

### ADC (Analog to Digital Converter)

Read analog voltages using the ESP32's built-in ADC.

```yaml
sensor:
  - platform: adc
    pin:
      number: GPIO1          # ADC pins: GPIO0-7 on ESP32-C6
    name: "Battery Voltage"
    update_interval: 30s
    # Note: Advanced filtering is planned for future releases
```

**ESP32-C6 ADC Pins:**
- GPIO0-GPIO7 (ADC1)
- 12-bit resolution
- 0-3.3V input range

**Common Uses:**
- Battery monitoring
- Light sensors (photoresistors)
- Potentiometers
- Analog sensors

## Switch Components

Switches are output devices that can be turned on or off.

### GPIO Switch

Control digital outputs like relays, LEDs, or other devices.

```yaml
switch:
  - platform: gpio
    pin:
      number: GPIO5
    name: "Relay Control"
    inverted: false          # true = active low
    restore_mode: RESTORE_DEFAULT_OFF
    # Note: Automation actions are planned for future releases
```

**Restore Modes:**
- `RESTORE_DEFAULT_OFF` - Remember state, default off
- `RESTORE_DEFAULT_ON` - Remember state, default on
- `ALWAYS_OFF` - Always start off
- `ALWAYS_ON` - Always start on

**Common Uses:**
- Relay modules
- LED control
- Motor drivers
- Solenoid valves

## Light Components

Lights are specialized outputs with brightness and color control.

### Binary Light

Simple on/off light control.

```yaml
light:
  - platform: binary
    pin:
      number: GPIO2
    name: "Status LED"
    # Note: Light effects are planned for future releases
```

### RGB Light

Full color control with red, green, and blue channels.

```yaml
light:
  - platform: rgb
    red_pin:
      number: GPIO6
    green_pin:
      number: GPIO7
    blue_pin:
      number: GPIO8
    name: "RGB Strip"
    # Note: Light effects are planned for future releases
```

**RGBW Light (with white channel):**
```yaml
light:
  - platform: rgb
    red_pin:
      number: GPIO6
    green_pin:
      number: GPIO7
    blue_pin:
      number: GPIO8
    white_pin:
      number: GPIO9
    name: "RGBW Strip"
```

**PWM Frequency:**
- Default: 1kHz
- Adjustable for LED compatibility
- Higher frequency = less flicker

## Binary Sensor Components

Binary sensors detect on/off states like buttons, motion, or contact.

### GPIO Binary Sensor

Read digital inputs from switches, buttons, or digital sensors.

```yaml
binary_sensor:
  - platform: gpio_binary
    pin:
      number: GPIO3
      mode: INPUT_PULLUP
      inverted: true         # true for active-low
    name: "Push Button"
    device_class: button
    # Note: Advanced filtering and automation actions are planned for future releases
```

**Common Device Classes:**
- `button` - Push button
- `door` - Door sensor
- `motion` - PIR sensor
- `window` - Window sensor
- `presence` - Presence detection

## Planned Advanced Features

> **Note**: The following features are planned for future releases:

### Component Actions & Automations
- Trigger actions on component state changes
- On-device automation rules
- Conditional logic and delays

### Advanced Filtering
- Sensor value processing and smoothing
- Custom mathematical operations
- Multi-point calibration

### Light Effects
- Built-in patterns (rainbow, strobe, fade)
- Custom effect sequences
- Synchronized multi-light control

## Swift Embedded Architecture

ESPHome Swift uses a modern, type-safe component architecture following Swift Embedded best practices:

### Type Safety Benefits
- **Compile-time validation**: Component configurations are validated at build time, not runtime
- **Associated types**: Each factory specifies its exact configuration type, eliminating unsafe downcasting
- **Memory efficiency**: Value types (structs) and @frozen optimizations for embedded performance
- **Zero-cost abstractions**: Type erasure allows heterogeneous collections without runtime overhead

### Shared Utilities
- **PinValidator**: Centralized pin validation with ESP32-C6 board constraints
- **BoardConstraints**: Abstracted hardware limitations for different ESP32 variants
- **PinRequirements**: Type-safe specification of pin capabilities (ADC, PWM, input/output)

### Security & Performance
- **Secure code generation**: Protected against injection vulnerabilities
- **Optimized for embedded**: Minimal binary footprint and efficient execution
- **Board-specific validation**: Hardware constraints enforced at development time

## Creating Custom Components

To add a new component type to ESPHome Swift:

### 1. Create Component Factory

```swift
// Sources/ComponentLibrary/Sensors/MySensor.swift
import Foundation
import ESPHomeSwiftCore

public struct MySensorFactory: ComponentFactory {
    public typealias ConfigType = SensorConfig
    
    public let platform = "my_sensor"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin", "type"]
    public let optionalProperties = ["name", "update_interval"]
    
    private let pinValidator: PinValidator
    
    public init(pinValidator: PinValidator = PinValidator()) {
        self.pinValidator = pinValidator
    }
    
    public func validate(config: SensorConfig) throws {
        // Validate required pin with shared validator
        guard let pin = config.pin else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Use shared pin validation with requirements
        try pinValidator.validatePin(pin, requirements: .input)
    }
    
    public func generateCode(
        config: SensorConfig, 
        context: CodeGenerationContext
    ) throws -> ComponentCode {
        let pinNumber = try pinValidator.extractPinNumber(from: config.pin!)
        
        // Generate type-safe C++ code
        return ComponentCode(
            headerIncludes: ["#include \"my_sensor.h\""],
            globalDeclarations: ["MySensor sensor(\(pinNumber));"],
            setupCode: ["sensor.begin();"],
            loopCode: ["sensor.update();"]
        )
    }
}
```

### 2. Register Component

```swift
// In ComponentLibrary.swift
private func registerBuiltInComponents() {
    // ... existing components ...
    register(MySensorFactory())
}
```

### 3. Add Tests

```swift
// Tests/ComponentLibraryTests/MySensorTests.swift
import XCTest
@testable import ComponentLibrary

final class MySensorTests: XCTestCase {
    func testMySensorValidation() throws {
        // Test component validation
    }
    
    func testMySensorCodeGeneration() throws {
        // Test code generation
    }
}
```

## Component Roadmap

### In Development
- **I2C Components** - BME280, BMP280, SSD1306
- **SPI Components** - MAX31855, SD card
- **One-Wire** - DS18B20 temperature
- **UART** - GPS, PM2.5 sensors
- **PWM** - Servo, motor control

### Planned
- **Displays** - LCD, OLED, e-Paper
- **Audio** - Buzzer, I2S
- **Networking** - MQTT, HTTP requests
- **Advanced Sensors** - IMU, distance, gas
- **Home Assistant** - Custom entities

## Contributing Components

We welcome contributions! To add a new component:

1. Check existing [issues](https://github.com/ryan-graves/esphome-swift/issues) for requests
2. Discuss your component idea in [discussions](https://github.com/ryan-graves/esphome-swift/discussions)
3. Follow the [Contributing Guide](https://github.com/ryan-graves/esphome-swift/blob/main/CONTRIBUTING.md)
4. Submit a pull request with:
   - Component implementation
   - Tests
   - Documentation
   - Example configuration

## Component Best Practices

1. **Type Safety** - Use struct ComponentFactory with associated types for compile-time guarantees
2. **Shared Validation** - Leverage PinValidator for consistent pin validation across components
3. **Value Types** - Use structs instead of classes for memory efficiency and performance
4. **Pin Requirements** - Specify exact pin capabilities (ADC, PWM, input/output) for validation
5. **Error Handling** - Provide clear, actionable error messages with ComponentValidationError
6. **Documentation** - Include wiring diagrams, examples, and ESP32-C6 specific notes
7. **Testing** - Test on actual hardware with comprehensive unit tests
8. **Board Constraints** - Respect ESP32-C6 hardware limitations (pins 0-30, input-only pins 18-19)
9. **Performance** - Consider power consumption, timing, and use @frozen for critical structs