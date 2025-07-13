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
    pin: GPIO4
    model: DHT22              # DHT11, DHT22, or AM2302
    temperature:
      name: "Room Temperature"
      unit_of_measurement: "°C"
      accuracy_decimals: 1
      filters:
        - offset: -0.5        # Calibration offset
    humidity:
      name: "Room Humidity"
      unit_of_measurement: "%"
      accuracy_decimals: 0
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
    pin: GPIO1               # ADC pins: GPIO0-7 on ESP32-C6
    name: "Battery Voltage"
    update_interval: 30s
    unit_of_measurement: "V"
    accuracy_decimals: 2
    filters:
      - multiply: 3.3        # Convert to voltage (0-3.3V)
      - calibrate_linear:    # Two-point calibration
          - 0.0 -> 0.0
          - 3.3 -> 3.27
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
    pin: GPIO5
    name: "Relay Control"
    id: relay1
    inverted: false          # true = active low
    restore_mode: RESTORE_DEFAULT_OFF
    on_turn_on:
      - logger.log: "Relay turned on"
    on_turn_off:
      - logger.log: "Relay turned off"
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
    pin: GPIO2
    name: "Status LED"
    id: status_led
    effects:
      - strobe:
          name: "Alarm"
          colors:
            - state: true
              duration: 500ms
            - state: false
              duration: 500ms
```

### RGB Light

Full color control with red, green, and blue channels.

```yaml
light:
  - platform: rgb
    red_pin: GPIO6
    green_pin: GPIO7
    blue_pin: GPIO8
    name: "RGB Strip"
    effects:
      - random:
          name: "Random Colors"
          transition_length: 5s
          update_interval: 7s
      - strobe:
          name: "Police"
          colors:
            - red: 100%
              green: 0%
              blue: 0%
              duration: 300ms
            - red: 0%
              green: 0%
              blue: 100%
              duration: 300ms
```

**RGBW Light (with white channel):**
```yaml
light:
  - platform: rgb
    red_pin: GPIO6
    green_pin: GPIO7
    blue_pin: GPIO8
    white_pin: GPIO9
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
    filters:
      - delayed_on: 50ms     # Debounce
      - delayed_off: 50ms
    on_press:
      - logger.log: "Button pressed"
    on_release:
      - logger.log: "Button released"
    on_click:
      min_length: 50ms
      max_length: 500ms
      then:
        - logger.log: "Single click"
    on_double_click:
      min_length: 50ms
      max_length: 500ms
      then:
        - logger.log: "Double click"
```

**Common Device Classes:**
- `button` - Push button
- `door` - Door sensor
- `motion` - PIR sensor
- `window` - Window sensor
- `presence` - Presence detection

## Advanced Component Features

### Component Actions

Components can trigger actions on state changes:

```yaml
binary_sensor:
  - platform: gpio
    # ... configuration ...
    on_press:
      - switch.turn_on: relay1
      - delay: 5s
      - switch.turn_off: relay1
```

### Filters

Process sensor values before sending:

```yaml
sensor:
  - platform: adc
    # ... configuration ...
    filters:
      # Remove noise
      - sliding_window_moving_average:
          window_size: 15
          send_every: 5
      
      # Calibration
      - calibrate_linear:
          - 0.0 -> 0.0
          - 100.0 -> 95.5
      
      # Custom processing
      - lambda: |-
          if (x > 30) {
            return x * 1.05;
          } else {
            return x;
          }
```

### Automations

Create on-device automations:

```yaml
binary_sensor:
  - platform: gpio
    pin: GPIO3
    name: "Motion Sensor"
    on_press:
      then:
        - light.turn_on: 
            id: hallway_light
            brightness: 100%
        - delay: 5min
        - light.turn_off: hallway_light
```

## Creating Custom Components

To add a new component type to ESPHome Swift:

### 1. Create Component Factory

```swift
// Sources/ComponentLibrary/Sensors/MySensor.swift
import Foundation
import ESPHomeSwiftCore

public class MySensorFactory: ComponentFactory {
    public let platform = "my_sensor"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin", "type"]
    public let optionalProperties = ["name", "update_interval"]
    
    public func validate(config: ComponentConfig) throws {
        // Validate configuration
    }
    
    public func generateCode(
        config: ComponentConfig, 
        context: CodeGenerationContext
    ) throws -> ComponentCode {
        // Generate C++ code
        return ComponentCode(
            headerIncludes: ["#include \"my_sensor.h\""],
            globalDeclarations: ["MySensor sensor;"],
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

1. **Validation** - Thoroughly validate configurations
2. **Error Handling** - Provide clear error messages
3. **Documentation** - Include wiring diagrams and examples
4. **Testing** - Test on actual hardware
5. **Compatibility** - Note board-specific limitations
6. **Performance** - Consider power consumption and timing