---
layout: default
title: Getting Started
---

# Getting Started with ESPHome Swift

This guide will walk you through setting up ESPHome Swift and creating your first project.

## Prerequisites

Before you begin, ensure you have:

- **macOS, Linux, or Windows** development environment (full cross-platform support)
- **Swift 5.9+** installed (Swift 6.0+ recommended)
- **ESP-IDF v5.3+** for building firmware
- An **ESP32-C3/C6/H2/P4** development board
- USB cable for flashing

## Installation

### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/ryan-graves/esphome-swift.git
cd esphome-swift

# Build the project
swift build -c release

# Install to /usr/local/bin
sudo cp .build/release/esphome-swift /usr/local/bin/
```

### Option 2: Download Pre-built Binary

Download the latest release from the [GitHub Releases](https://github.com/ryan-graves/esphome-swift/releases) page.

```bash
# Extract and install
tar xzf esphome-swift-*.tar.gz
sudo mv esphome-swift /usr/local/bin/
```

### Verify Installation

```bash
esphome-swift --version
```

## Setting Up ESP-IDF

ESPHome Swift requires ESP-IDF to build firmware for ESP32 devices.

### macOS

```bash
# Install dependencies
brew install cmake ninja dfu-util

# Clone ESP-IDF
mkdir -p ~/esp
cd ~/esp
git clone -b v5.3 --recursive https://github.com/espressif/esp-idf.git

# Install ESP-IDF
cd esp-idf
./install.sh esp32c3,esp32c6,esp32h2

# Source the environment
. ./export.sh
```

### Linux

```bash
# Install dependencies
sudo apt-get install git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# Clone and install ESP-IDF
mkdir -p ~/esp
cd ~/esp
git clone -b v5.3 --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
./install.sh esp32c3,esp32c6,esp32h2
. ./export.sh
```

### Windows

For Windows development, we recommend using WSL2 (Windows Subsystem for Linux) or Docker:

#### Option 1: WSL2
1. Install WSL2 with Ubuntu
2. Follow the Linux instructions above within WSL2

#### Option 2: Docker
```bash
# Use official ESP-IDF Docker image
docker run --rm -v ${PWD}:/project -w /project espressif/idf:v5.3 idf.py build
```

## Your First Project

### 1. Create a New Project

```bash
esphome-swift new living-room-sensor
cd living-room-sensor
```

This creates:
- `living-room-sensor.yaml` - Configuration file
- Project directory structure

### 2. Configure Your Device

Edit `living-room-sensor.yaml`:

```yaml
esphome_swift:
  name: living_room_sensor
  friendly_name: "Living Room Sensor"

esp32:
  board: esp32-c6-devkitc-1
  framework:
    type: esp-idf

# Configure WiFi
wifi:
  ssid: "YourWiFiName"
  password: "YourWiFiPassword"
  
  # Fallback hotspot (captive portal)
  ap:
    ssid: "Living Room Fallback"
    password: "12345678"

# Enable logging
logger:
  level: INFO

# Enable Home Assistant API
api:
  encryption:
    key: "your-32-character-encryption-key-here"

# Enable OTA updates
ota:
  - platform: esphome_swift

# Add a temperature sensor
sensor:
  - platform: dht
    pin:
      number: GPIO4
    model: DHT22
    temperature:
      name: "Living Room Temperature"
    humidity:
      name: "Living Room Humidity"
    update_interval: 60s
```

### 3. Create Secrets File

Create a `secrets.yaml` file in the same directory:

```yaml
wifi_ssid: "YourWiFiName"
wifi_password: "YourWiFiPassword"
api_encryption_key: "your-32-character-encryption-key-here"
```

Update your configuration to use secrets:

```yaml
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_encryption_key
```

### 4. Validate Configuration

```bash
esphome-swift validate living-room-sensor.yaml
```

### 5. Build Firmware

```bash
# Make sure ESP-IDF is sourced
. ~/esp/esp-idf/export.sh

# Build the firmware
esphome-swift build living-room-sensor.yaml
```

### 6. Flash to Device

Connect your ESP32 board via USB, then:

```bash
# Find your serial port
ls /dev/tty.*  # macOS
ls /dev/ttyUSB*  # Linux

# Flash the firmware
esphome-swift flash living-room-sensor --port /dev/ttyUSB0
```

### 7. Monitor Output

```bash
esphome-swift monitor living-room-sensor --port /dev/ttyUSB0
```

You should see:
- Boot messages
- WiFi connection status
- Sensor readings every 60 seconds

## Home Assistant Integration

### 1. Auto-Discovery

If your ESP32 and Home Assistant are on the same network, the device should appear automatically in:
- Settings → Devices & Services → Discovered

### 2. Manual Integration

If not auto-discovered:

1. Go to Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "ESPHome"
4. Enter the device IP address
5. Enter the encryption key from your configuration

## Troubleshooting

### WiFi Won't Connect

- Double-check SSID and password
- Ensure 2.4GHz network (ESP32 doesn't support 5GHz)
- Try the fallback AP mode

### Build Fails

- Ensure ESP-IDF is properly sourced: `. ~/esp/esp-idf/export.sh`
- Check Swift version: `swift --version` (need 6.0+)
- Verify board type matches your hardware

### Flash Fails

- Check USB cable (some are charge-only)
- Install USB drivers if needed
- Try lower baud rate: `--baud-rate 115200`
- Hold BOOT button while flashing starts

### No Sensor Readings

- Verify wiring connections
- Check pin numbers match configuration
- Monitor serial output for errors
- Ensure sensor model matches hardware

## Next Steps

- Explore the [Component Library](components.html)
- Learn about [Advanced Configuration](configuration.html)
- Add more sensors and automation
- Contribute to the project on [GitHub](https://github.com/ryan-graves/esphome-swift)