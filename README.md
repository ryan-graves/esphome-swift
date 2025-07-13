# ESPHome Swift

[![CI](https://github.com/ryan-graves/esphome-swift/workflows/CI/badge.svg)](https://github.com/ryan-graves/esphome-swift/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![ESP-IDF](https://img.shields.io/badge/ESP--IDF-v5.3-blue.svg)](https://github.com/espressif/esp-idf)
[![Documentation](https://img.shields.io/badge/docs-github.io-blue.svg)](https://ryan-graves.github.io/esphome-swift/)

A Swift-based replacement for ESPHome that generates Embedded Swift firmware for ESP32 microcontrollers from declarative YAML configuration files.

## Project Overview

ESPHome Swift brings the power and type safety of Swift to embedded IoT development, targeting ESP32 RISC-V microcontrollers (ESP32-C3, C6, H2, P4) with Embedded Swift for minimal binary footprint and optimal performance.

## Core Architecture

### Configuration System
- **YAML Input**: Familiar ESPHome-style configuration files
- **Swift Parser**: Native Swift YAML parsing with Foundation/Yams
- **Schema Validation**: Type-safe validation with descriptive error messages
- **Component Registry**: Extensible component registration system

### Code Generation Engine
- **Template-Based**: Swift code generation from YAML to Embedded Swift
- **Modular Components**: Sensors, actuators, networking, automation
- **ESP-IDF Integration**: Seamless integration with Espressif's development framework
- **Binary Optimization**: Leverages Embedded Swift's minimal footprint

### Target Platforms
- ESP32-C3, ESP32-C6, ESP32-H2, ESP32-P4 (RISC-V architecture)
- WiFi, Bluetooth, Matter protocol support
- Over-the-air (OTA) firmware updates
- Home Assistant native API integration

## Project Structure

```
ESPHomeSwift/
├── Sources/
│   ├── ESPHomeSwiftCore/          # Core configuration & validation
│   ├── CodeGeneration/            # Swift code generation engine
│   ├── ComponentLibrary/          # Built-in component definitions
│   ├── CLI/                       # Command-line interface
│   └── WebDashboard/              # Web-based monitoring
├── Resources/
│   ├── Templates/                 # Embedded Swift code templates
│   └── Schemas/                   # YAML validation schemas
├── Examples/                      # Sample configurations
└── Tests/                         # Unit and integration tests
```

## Implementation Roadmap

### Phase 1: Foundation (MVP)
- [x] Project planning and documentation
- [ ] Swift Package Manager setup
- [ ] Basic YAML parsing and validation
- [ ] Simple component system (GPIO, LED, basic sensors)
- [ ] Code generation for ESP32-C6
- [ ] CLI for build/flash operations

### Phase 2: Core Features
- [ ] Extended component library
- [ ] WiFi and API integration
- [ ] OTA update system
- [ ] Web dashboard for monitoring

### Phase 3: Advanced Features
- [ ] Home Assistant integration
- [ ] Matter protocol support
- [ ] Advanced automation engine
- [ ] Plugin system for custom components

## Key Differentiators

- **Type Safety**: Swift's strong typing system prevents configuration errors at compile time
- **Memory Safety**: Automatic memory management with compile-time guarantees
- **Modern Tooling**: Leverages Swift Package Manager and Xcode ecosystem
- **Embedded Swift**: Optimized compilation mode for microcontrollers
- **Developer Experience**: Superior error messages and debugging capabilities
- **Extensible Architecture**: Plugin-based component system for custom functionality

## Requirements

- Swift 6.0+ (nightly toolchain for Embedded Swift)
- ESP-IDF v5.3+
- macOS or Linux development environment
- ESP32-C3/C6/H2/P4 development board

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

```bash
# Create a new project
esphome-swift new my-sensor

# Edit configuration (see documentation for details)
cd my-sensor

# Build and flash
esphome-swift build my-sensor.yaml
esphome-swift flash my-sensor
```

## Documentation

📚 **[Complete Documentation](https://ryan-graves.github.io/esphome-swift/)**

- [Getting Started Guide](https://ryan-graves.github.io/esphome-swift/getting-started.html)
- [Configuration Reference](https://ryan-graves.github.io/esphome-swift/configuration.html)  
- [Component Library](https://ryan-graves.github.io/esphome-swift/components.html)

## Example Configuration

```yaml
esphome_swift:
  name: living-room-sensor
  friendly_name: "Living Room Sensor"

esp32:
  board: esp32-c6-devkitc-1
  framework: esp-idf

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_encryption_key

ota:
  - platform: esphome_swift

sensor:
  - platform: dht
    pin: GPIO4
    model: DHT22
    temperature:
      name: "Living Room Temperature"
    humidity:
      name: "Living Room Humidity"
    update_interval: 60s

switch:
  - platform: gpio
    pin: GPIO5
    name: "Living Room Light"
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- 🐛 [Reporting bugs](CONTRIBUTING.md#reporting-bugs)
- 💡 [Suggesting enhancements](CONTRIBUTING.md#suggesting-enhancements) 
- 🔧 [Adding new components](CONTRIBUTING.md#adding-new-components)
- 📖 [Improving documentation](CONTRIBUTING.md#documentation)

## Community

- 💬 [GitHub Discussions](https://github.com/ryan-graves/esphome-swift/discussions) - Ask questions and share ideas
- 🐛 [Issue Tracker](https://github.com/ryan-graves/esphome-swift/issues) - Report bugs and request features
- 📖 [Documentation](https://ryan-graves.github.io/esphome-swift/) - Complete guides and references

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.