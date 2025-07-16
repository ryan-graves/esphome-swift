---
layout: default
title: ESPHome Swift
---

# ESPHome Swift

A Swift-based replacement for ESPHome that generates Embedded Swift firmware for ESP32 microcontrollers from declarative YAML configuration files.

## Features

- 🚀 **Native Swift Implementation** - Type-safe configuration and code generation
- 📱 **ESP32 RISC-V Support** - Targets ESP32-C3, C6, H2, and P4 boards
- 🌐 **Matter Protocol Support** - WiFi and Thread networking for ESP32-C6/H2 boards
- 🔧 **Extensible Component System** - Easy to add new sensors and actuators
- 🏠 **Home Assistant Compatible** - Native API integration
- 📦 **Simple YAML Configuration** - Familiar ESPHome-style syntax
- 🔄 **OTA Updates** - Update firmware over-the-air

## Quick Start

### Installation

#### From Source
```bash
git clone https://github.com/ryan-graves/esphome-swift.git
cd esphome-swift
swift build -c release
sudo cp .build/release/esphome-swift /usr/local/bin/
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
cd my-sensor
esphome-swift build my-sensor.yaml
esphome-swift flash build/my-sensor
```

## Documentation

- [Build Your First Smart Home Device](first-device-tutorial.html) - Complete beginner's guide
- [Getting Started Guide](getting-started.html) - Technical installation and setup
- [Configuration Reference](configuration.html)
- [Component Library](components.html)
- [API Reference](api.html)
- [Contributing Guide](https://github.com/ryan-graves/esphome-swift/blob/main/CONTRIBUTING.md)

## Supported Components

### Sensors
- **DHT** - Temperature and humidity (DHT11, DHT22, AM2302)
- **ADC** - Analog input readings

### Binary Sensors
- **GPIO Binary Sensor** - Digital input with debouncing

### Switches
- **GPIO Switch** - Digital output control

### Lights
- **Binary Light** - Simple on/off lighting
- **RGB Light** - Full color LED control

### Matter Protocol
- **25+ Device Types** - Lights, sensors, switches, locks, thermostats
- **Thread Networking** - Mesh networking for ESP32-C6/H2
- **WiFi Transport** - Standard WiFi connectivity option
- **Type-safe Configuration** - Validated Matter device definitions
- **ESP-Matter SDK** - Full Espressif Matter integration

### Coming Soon
- I2C sensors (BME280, BMP280, etc.)
- SPI devices
- Climate control
- Covers and fans
- Display support

## Example Projects

### Temperature Monitor
```yaml
sensor:
  - platform: dht
    pin:
      number: GPIO4
    model: DHT22
    temperature:
      name: "Room Temperature"
    humidity:
      name: "Room Humidity"
    update_interval: 60s
```

### Smart Switch
```yaml
switch:
  - platform: gpio
    pin:
      number: GPIO5
    name: "Living Room Light"
    restore_mode: ALWAYS_OFF
```

### RGB Mood Light
```yaml
light:
  - platform: rgb
    red_pin:
      number: GPIO6
    green_pin:
      number: GPIO7
    blue_pin:
      number: GPIO8
    name: "Mood Light"
```

### Matter Temperature Sensor
```yaml
# ESP32-C6 with Matter support
esp32:
  board: esp32-c6-devkitc-1
  framework:
    type: esp-idf

matter:
  enabled: true
  device_type: temperature_sensor
  vendor_id: 0xFFF1
  product_id: 0x8000
  commissioning:
    discriminator: 3840
    passcode: 20202021
  network:
    transport: wifi

sensor:
  - platform: dht
    pin: GPIO4
    model: DHT22
    temperature:
      name: "Room Temperature"
```

## License

ESPHome Swift is released under the MIT License. See [LICENSE](https://github.com/ryan-graves/esphome-swift/blob/main/LICENSE) for details.

## Links

- [GitHub Repository](https://github.com/ryan-graves/esphome-swift)
- [Issue Tracker](https://github.com/ryan-graves/esphome-swift/issues)
- [Discussions](https://github.com/ryan-graves/esphome-swift/discussions)