---
layout: default
title: ESPHome Swift
---

# ESPHome Swift

A Swift-based replacement for ESPHome that generates Embedded Swift firmware for ESP32 microcontrollers from declarative YAML configuration files.

## Features

- 🚀 **Native Swift Implementation** - Type-safe configuration and code generation
- 📱 **ESP32 RISC-V Support** - Targets ESP32-C3, C6, H2, and P4 boards
- 🔧 **Extensible Component System** - Easy to add new sensors and actuators
- 🏠 **Home Assistant Compatible** - Native API integration
- 📦 **Simple YAML Configuration** - Familiar ESPHome-style syntax
- 🔄 **OTA Updates** - Update firmware over-the-air

## Quick Start

### Installation

#### Homebrew (coming soon)
```bash
brew tap ryan-graves/esphome-swift
brew install esphome-swift
```

#### From Source
```bash
git clone https://github.com/ryan-graves/esphome-swift.git
cd esphome-swift
swift build -c release
cp .build/release/esphome-swift /usr/local/bin/
```

### Create Your First Project

1. Create a new project:
```bash
esphome-swift new my-sensor
```

2. Edit the configuration file:
```yaml
esphome_swift:
  name: my-sensor
  friendly_name: "My Sensor"

esp32:
  board: esp32-c6-devkitc-1
  framework:
    type: esp-idf

wifi:
  ssid: "MyWiFi"
  password: "MyPassword"

sensor:
  - platform: dht
    pin: GPIO4
    model: DHT22
    temperature:
      name: "Temperature"
    humidity:
      name: "Humidity"
```

3. Build and flash:
```bash
esphome-swift build my-sensor/my-sensor.yaml
esphome-swift flash my-sensor
```

## Documentation

- [Getting Started Guide](getting-started.html)
- [Configuration Reference](configuration.html)
- [Component Library](components.html)
- [API Reference](api.html)
- [Contributing Guide](https://github.com/ryan-graves/esphome-swift/blob/main/CONTRIBUTING.md)

## Supported Components

### Sensors
- **DHT** - Temperature and humidity (DHT11, DHT22, AM2302)
- **ADC** - Analog input readings
- **GPIO** - Binary sensor input

### Outputs
- **GPIO Switch** - Digital output control
- **Binary Light** - Simple on/off lighting
- **RGB Light** - Full color LED control

### Coming Soon
- I2C sensors (BME280, BMP280, etc.)
- SPI devices
- PWM outputs
- Servo control
- Display support

## Example Projects

### Temperature Monitor
```yaml
sensor:
  - platform: dht
    pin: GPIO4
    model: DHT22
    temperature:
      name: "Room Temperature"
      filters:
        - offset: -0.5
    humidity:
      name: "Room Humidity"
```

### Smart Switch
```yaml
switch:
  - platform: gpio
    pin: GPIO5
    name: "Living Room Light"
    restore_mode: RESTORE_DEFAULT_OFF
```

### RGB Mood Light
```yaml
light:
  - platform: rgb
    red_pin: GPIO6
    green_pin: GPIO7
    blue_pin: GPIO8
    name: "Mood Light"
    effects:
      - name: "Rainbow"
        type: rainbow
```

## License

ESPHome Swift is released under the MIT License. See [LICENSE](https://github.com/ryan-graves/esphome-swift/blob/main/LICENSE) for details.

## Links

- [GitHub Repository](https://github.com/ryan-graves/esphome-swift)
- [Issue Tracker](https://github.com/ryan-graves/esphome-swift/issues)
- [Discussions](https://github.com/ryan-graves/esphome-swift/discussions)