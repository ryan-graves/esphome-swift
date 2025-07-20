# ESPHome Swift

[![CI](https://github.com/ryan-graves/esphome-swift/workflows/CI/badge.svg)](https://github.com/ryan-graves/esphome-swift/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
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
- **Template-Based**: Swift code generation from YAML to C/C++ for ESP-IDF
- **Modular Components**: Sensors, actuators, networking, automation
- **ESP-IDF Integration**: Seamless integration with Espressif's development framework
- **Production Ready**: Generates optimized C code for reliable embedded operation

## Why Swift Generates C Code?

**ESPHome Swift uses a hybrid architecture**: Swift for development-time type safety and code generation, C/C++ for runtime execution on ESP32.

### Development Flow
```
YAML Config → Swift Parser → C/C++ Code Generation → ESP-IDF Build → ESP32 Firmware
```

### Why This Approach?

1. **ESP32 Compatibility**: ESP32 microcontrollers run ESP-IDF (C/C++ framework) with proven stability
2. **Production Ready**: C/C++ toolchain is mature and well-tested for embedded systems
3. **Memory Efficiency**: No Swift runtime overhead on resource-constrained microcontrollers
4. **Hardware Integration**: Direct access to ESP-IDF APIs and peripheral drivers
5. **ESPHome Ecosystem**: Compatible with existing ESPHome patterns and Home Assistant integration

### Swift Embedded Future

While **Swift Embedded** is advancing rapidly, ESP32 RISC-V support is still experimental. Our architecture provides:
- ✅ **Type safety** at development time (Swift)
- ✅ **Reliability** at runtime (C/C++)
- ✅ **Migration path** to native Swift when the ecosystem matures

When Swift Embedded fully supports ESP32 (expected 2025-2026), we can offer both approaches while maintaining backward compatibility.

### Target Platforms
- ESP32-C3, ESP32-C6, ESP32-H2, ESP32-P4 (RISC-V architecture)
- **WiFi, Bluetooth, and Matter protocol** with Thread/802.15.4 mesh networking (ESP32-C6/H2)
- Over-the-air (OTA) firmware updates
- Home Assistant native API integration

## Project Structure

```
ESPHomeSwift/
├── Sources/
│   ├── ESPHomeSwiftCore/          # Core configuration & validation
│   ├── CodeGeneration/            # Swift code generation engine
│   ├── ComponentLibrary/          # Built-in component definitions
│   ├── MatterSupport/             # Matter protocol implementation
│   ├── CLI/                       # Command-line interface
│   └── WebDashboard/              # Web-based monitoring
├── Resources/
│   ├── Templates/                 # Embedded Swift code templates
│   └── Schemas/                   # YAML validation schemas
├── Examples/                      # Sample configurations
└── Tests/                         # Unit and integration tests
```

## Implementation Status

### ✅ Phase 1: Foundation (MVP) - COMPLETED
- [x] Project planning and comprehensive documentation
- [x] Swift Package Manager setup with modular architecture
- [x] Complete YAML parsing and validation system
- [x] Extensible component system with built-in components
- [x] Code generation engine for Embedded Swift/ESP-IDF
- [x] Full CLI with project management (new, build, flash, validate)
- [x] Unit testing framework and example configurations

### ✅ Phase 2: Core Features - COMPLETED  
- [x] Component library (DHT, GPIO, ADC, RGB lights, binary sensors)
- [x] Board capabilities system with multi-board validation
- [x] WiFi and API integration framework
- [x] OTA update system support
- [x] Web dashboard foundation (monitoring interface)
- [x] GitHub Actions CI/CD with cross-platform testing (macOS, Linux)
- [x] SwiftLint and SwiftFormat code quality tools
- [x] Documentation site with GitHub Pages

### 🚧 Phase 3: Advanced Features - IN PROGRESS
- [x] Home Assistant API compatibility framework
- [x] **Matter protocol support** (ESP32-C6/H2 with Thread networking)
- [x] **25+ Matter device types** (lights, sensors, switches, locks)
- [x] **WiFi and Thread transport** with comprehensive validation
- [ ] **Component Library ESP-IDF Migration** - Replace Arduino-style APIs with native ESP-IDF C APIs for all sensors/actuators
- [ ] Plugin system architecture for custom components
- [ ] Advanced automation engine with on-device rules
- [ ] Advanced sensor filters and data processing
- [ ] Multi-device management and discovery

### 🔮 Phase 4: Future Enhancements
- [ ] Visual configuration editor (web-based)
- [ ] Device firmware OTA management portal
- [ ] Advanced debugging and monitoring tools
- [ ] Integration with other home automation platforms
- [ ] Mobile companion app for device management
- [ ] [Matter protocol enhancements](docs/matter-roadmap.md) (QR code generation, advanced security, extended device types)

## Key Differentiators

- **Type Safety**: Swift's strong typing system prevents configuration errors at compile time
- **Memory Safety**: Automatic memory management with compile-time guarantees
- **Board-Aware Validation**: Hardware constraints enforced for ESP32-C3, C6, H2, P4 variants
- **Matter Protocol**: Full Matter/Thread support for interoperable smart home devices
- **Modern Tooling**: Leverages Swift Package Manager and Xcode ecosystem
- **Embedded Swift**: Optimized compilation mode for microcontrollers
- **Developer Experience**: Superior error messages and debugging capabilities
- **Extensible Architecture**: Plugin-based component system for custom functionality

## Requirements

- **Swift 5.9+** (Swift 6.0+ recommended for Embedded Swift)
- **ESP-IDF v5.3+** for firmware compilation
- **macOS, Linux, or Windows** development environment (full cross-platform support)
- **ESP32-C3/C6/H2/P4** development board (RISC-V architecture)

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

# Enable Matter protocol support
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
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- 🐛 [Reporting bugs](CONTRIBUTING.md#reporting-bugs)
- 💡 [Suggesting enhancements](CONTRIBUTING.md#suggesting-enhancements) 
- 🔧 [Adding new components](CONTRIBUTING.md#adding-new-components)
- 📖 [Improving documentation](CONTRIBUTING.md#documentation)

### Development Workflow

ESPHome Swift follows a Git Flow inspired branching strategy:

- **`main`** - Production-ready code (protected)
- **`develop`** - Integration branch for new features
- **`feature/`** - New features and enhancements
- **`fix/`** - Bug fixes and improvements
- **`docs/`** - Documentation updates

**Quick Start:**
```bash
# Start a new feature
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# After development, create PR targeting 'develop' branch
```

For complete branching guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Community

- 💬 [GitHub Discussions](https://github.com/ryan-graves/esphome-swift/discussions) - Ask questions and share ideas
- 🐛 [Issue Tracker](https://github.com/ryan-graves/esphome-swift/issues) - Report bugs and request features
- 📖 [Documentation](https://ryan-graves.github.io/esphome-swift/) - Complete guides and references

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.