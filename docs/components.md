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
  - platform: gpio
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

## Matter Protocol Components

ESPHome Swift includes comprehensive Matter protocol support for building interoperable smart home devices on ESP32-C6 and ESP32-H2 boards.

### Matter Support Overview

Matter is an industry-standard protocol that enables smart home devices from different manufacturers to work together seamlessly. ESPHome Swift provides native Matter support with:

- **25+ Device Types** - Complete device type library covering lights, sensors, switches, locks, and appliances
- **Thread Networking** - Mesh networking capabilities using 802.15.4 radios on ESP32-C6/H2
- **WiFi Transport** - Standard WiFi connectivity for all Matter-enabled boards
- **Type-safe Configuration** - Compile-time validation of Matter device configurations
- **ESP-Matter SDK Integration** - Full Espressif Matter SDK support

### Supported Matter Device Types

#### Lighting Devices
- `on_off_light` - Simple on/off light control
- `dimmable_light` - Brightness control with level cluster
- `color_temperature_light` - Tunable white temperature
- `extended_color_light` - Full RGB color control

#### Switch Devices  
- `on_off_switch` - Basic switch functionality
- `dimmer_switch` - Dimmer with level control
- `color_dimmer_switch` - Color dimming capabilities
- `generic_switch` - Multi-function switch

#### Sensor Devices
- `temperature_sensor` - Temperature measurements
- `humidity_sensor` - Humidity readings
- `occupancy_sensor` - Motion/presence detection
- `contact_sensor` - Door/window contact sensing
- `light_sensor` - Ambient light measurement
- `air_quality_sensor` - Air quality monitoring

#### Smart Appliances
- `smart_plug` - Controllable outlet/plug
- `door_lock` - Electronic lock control
- `thermostat` - Climate control device
- `fan` - Fan speed and direction control
- `window_covering` - Blinds/shades automation

### Matter Configuration Example

```yaml
# Enable Matter protocol support
matter:
  enabled: true
  device_type: temperature_sensor
  vendor_id: 0xFFF1              # Test vendor ID
  product_id: 0x8000
  
  # Device commissioning setup
  commissioning:
    discriminator: 3840           # 12-bit commissioning discriminator
    passcode: 20202021           # Setup passcode for pairing
    manual_pairing_code: "34970112332" # Optional manual code
  
  # Thread network configuration (ESP32-C6/H2)
  thread:
    enabled: true
    network_name: "Home Network"
    channel: 15                   # 802.15.4 channel (11-26)
    pan_id: 0x1234               # Personal Area Network ID
  
  # Network transport settings
  network:
    transport: wifi               # wifi/thread options
    ipv6_enabled: true           # Enable IPv6 for Matter
    mdns:
      enabled: true
      hostname: "my-sensor"
```

### Thread Networking

Thread provides mesh networking capabilities for Matter devices using the 802.15.4 radio:

**Thread Configuration Options:**
- **Channel Selection** - Choose from 802.15.4 channels 11-26
- **Network Credentials** - PAN ID, Extended PAN ID, Network Key
- **Operational Dataset** - Complete Thread network configuration
- **Border Router** - Connects Thread network to IP networks

**Thread Requirements:**
- ESP32-C6 or ESP32-H2 microcontroller
- 802.15.4 radio support
- Thread Border Router in network
- IPv6 connectivity

### Matter Security Features

**Commissioning Security:**
- Secure device pairing with setup codes
- Certificate-based authentication
- Encrypted communication channels
- Device attestation certificates

**Network Security:**
- Thread network encryption
- Matter message encryption
- Access control lists (ACLs)
- Fabric isolation between ecosystems

### Hardware Requirements

**ESP32-C6 Capabilities:**
- WiFi 6 (802.11ax) + Bluetooth 5 LE
- Thread/802.15.4 radio
- Matter over WiFi and Thread
- 32-bit RISC-V processor

**ESP32-H2 Capabilities:**
- Bluetooth 5 LE + 802.15.4
- Thread networking only (no WiFi)
- Matter over Thread
- Ultra-low power design

### Matter Integration Patterns

```yaml
# Matter temperature sensor with DHT22
esp32:
  board: esp32-c6-devkitc-1

matter:
  enabled: true
  device_type: temperature_sensor
  network:
    transport: wifi

sensor:
  - platform: dht
    pin: GPIO4
    model: DHT22
    temperature:
      name: "Room Temperature"
    humidity:
      name: "Room Humidity"

# Matter smart switch with relay
matter:
  enabled: true
  device_type: on_off_switch

switch:
  - platform: gpio
    pin: GPIO5
    name: "Smart Switch"
    restore_mode: RESTORE_DEFAULT_OFF
```

### Development and Testing

**Test Configuration:**
- Use vendor ID `0xFFF1-0xFFF4` for development
- Test with Thread network simulators
- Validate with Matter certification tools
- Use Home Assistant Matter integration

**Production Deployment:**
- Obtain certified vendor ID from CSA
- Complete Matter certification process
- Configure production commissioning flow
- Deploy with Thread Border Router

For detailed Matter configuration options, see the [Configuration Reference](configuration.html#matter).

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