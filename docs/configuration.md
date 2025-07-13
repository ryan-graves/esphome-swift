---
layout: default
title: Configuration Reference
---

# Configuration Reference

ESPHome Swift uses YAML files to define device configuration. This reference covers all available configuration options.

## Core Configuration

### esphome_swift

The core configuration section defines basic device information.

```yaml
esphome_swift:
  name: device_name           # Required: Unique device identifier
  friendly_name: "My Device"  # Optional: Human-readable name
  comment: "Living room"      # Optional: Device description
  area_id: "living_room"      # Optional: Home Assistant area
```

**Requirements:**
- `name` must contain only lowercase letters, numbers, and underscores
- `name` must be unique across your devices

### esp32

Platform-specific configuration for ESP32 boards.

```yaml
esp32:
  board: esp32-c6-devkitc-1  # Required: Board identifier
  framework:
    type: esp-idf            # Required: Framework type
    version: "5.3"           # Optional: Framework version
  flash_size: "4MB"          # Optional: Flash memory size
```

**Supported Boards:**
- `esp32-c3-devkitm-1` - ESP32-C3 DevKit
- `esp32-c3-devkitc-02` - ESP32-C3 DevKit
- `esp32-c6-devkitc-1` - ESP32-C6 DevKit
- `esp32-h2-devkitm-1` - ESP32-H2 DevKit
- `esp32-p4-function-ev-board` - ESP32-P4 Board

**Framework Types:**
- `esp-idf` - Recommended for Embedded Swift
- `arduino` - Limited support

## Network Configuration

### wifi

Configure WiFi connectivity.

```yaml
wifi:
  ssid: "MyNetwork"          # Required: Network name
  password: "MyPassword"     # Required: Network password
  
  # Optional: Manual IP configuration
  manual_ip:
    static_ip: 192.168.1.100
    gateway: 192.168.1.1
    subnet: 255.255.255.0
    dns1: 8.8.8.8
    dns2: 8.8.4.4
  
  # Optional: Fallback access point
  ap:
    ssid: "Device Fallback"
    password: "12345678"     # Min 8 characters
  
  use_address: 192.168.1.100 # Optional: Override mDNS
```

## Services

### logger

Configure logging output.

```yaml
logger:
  level: INFO                # Log level
  baud_rate: 115200         # Serial baud rate
  tx_buffer: 512            # TX buffer size
```

**Log Levels:**
- `NONE` - No logging
- `ERROR` - Errors only
- `WARN` - Warnings and errors
- `INFO` - General information (default)
- `DEBUG` - Detailed debugging
- `VERBOSE` - Very detailed output
- `VERY_VERBOSE` - Maximum verbosity

### api

Enable Home Assistant API.

```yaml
api:
  encryption:
    key: "32-character-base64-key"  # Required for encryption
  port: 6053                        # Optional: API port
  password: "deprecated"            # Deprecated: Use encryption
  reboot_timeout: 15min            # Optional: Reboot if no client
```

### ota

Over-the-air update configuration.

```yaml
ota:
  - platform: esphome_swift
    password: "ota_password"  # Optional: OTA password
    id: my_ota               # Optional: OTA ID
```

## Components

### Sensors

#### DHT Temperature/Humidity

```yaml
sensor:
  - platform: dht
    pin:
      number: GPIO4          # Required: Data pin
      mode: INPUT            # Optional: Pin mode
    model: DHT22            # Required: DHT11/DHT22/AM2302
    temperature:
      name: "Temperature"
    humidity:
      name: "Humidity"
    update_interval: 60s    # Optional: Read interval
```

#### ADC (Analog Input)

```yaml
sensor:
  - platform: adc
    pin:
      number: GPIO1         # Required: ADC pin (0-7)
    name: "Battery Level"
    update_interval: 30s
    # Note: Advanced filtering is planned for future releases
```

### Switches

#### GPIO Switch

```yaml
switch:
  - platform: gpio
    pin:
      number: GPIO5        # Required: Output pin
      inverted: false      # Optional: Invert logic
      mode: OUTPUT         # Optional: Pin mode
    name: "Relay"
    id: relay_switch      # Optional: Internal ID
    restore_mode: RESTORE_DEFAULT_OFF
```

**Restore Modes:**
- `RESTORE_DEFAULT_OFF` - Restore state, default OFF
- `RESTORE_DEFAULT_ON` - Restore state, default ON
- `ALWAYS_OFF` - Always start OFF
- `ALWAYS_ON` - Always start ON
- `RESTORE_INVERTED_DEFAULT_OFF` - Restore inverted
- `RESTORE_INVERTED_DEFAULT_ON` - Restore inverted

### Lights

#### Binary Light

```yaml
light:
  - platform: binary
    pin:
      number: GPIO2       # Required: Output pin
    name: "Status LED"
    id: status_light
```

#### RGB Light

```yaml
light:
  - platform: rgb
    red_pin:
      number: GPIO6       # Required: Red channel
    green_pin:
      number: GPIO7       # Required: Green channel
    blue_pin:
      number: GPIO8       # Required: Blue channel
    white_pin:            # Optional: White channel
      number: GPIO9
    name: "RGB Light"
    # Note: Light effects are planned for future releases
```

### Binary Sensors

#### GPIO Binary Sensor

```yaml
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO3
      mode: INPUT_PULLUP  # Recommended for buttons
      inverted: true      # Optional: Invert logic
    name: "Button"
    device_class: button  # Optional: HA device class
    # Note: Advanced filtering is planned for future releases
```

**Device Classes:**
- `door`, `garage_door`, `window`
- `motion`, `occupancy`, `presence`
- `button`, `power`, `plug`
- `smoke`, `gas`, `moisture`
- `light`, `sound`, `vibration`
- `battery`, `cold`, `heat`
- `lock`, `opening`, `problem`
- `running`, `safety`, `tamper`

## Pin Configuration

### Simple Format

```yaml
pin: GPIO4               # Simple pin number
pin: 4                   # Integer format
```

### Advanced Format

```yaml
pin:
  number: GPIO4          # Pin number
  mode: INPUT_PULLUP     # Pin mode
  inverted: true         # Invert logic
```

**Pin Modes:**
- `INPUT` - Standard input
- `OUTPUT` - Standard output
- `INPUT_PULLUP` - Input with pullup resistor
- `INPUT_PULLDOWN` - Input with pulldown resistor
- `OUTPUT_OPEN_DRAIN` - Open drain output

## Filters

> **Note**: Advanced filtering capabilities are planned for future releases. Basic sensor reading and binary sensor input are currently supported.

## Secrets Management

Use `!secret` to reference values from `secrets.yaml`:

```yaml
# configuration.yaml
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

# secrets.yaml
wifi_ssid: "MyNetwork"
wifi_password: "MyPassword"
```

## Best Practices

1. **Use Secrets** - Never commit passwords or keys
2. **Unique Names** - Each device needs a unique name
3. **Pin Documentation** - Comment pin connections
4. **Update Intervals** - Balance accuracy vs. power
5. **Restore Modes** - Consider power loss behavior
6. **Filters** - Smooth noisy sensor readings
7. **Device Classes** - Use appropriate HA classes

## Example Configurations

### Basic Sensor Node

```yaml
esphome_swift:
  name: bedroom_sensor
  friendly_name: "Bedroom Sensor"

esp32:
  board: esp32-c6-devkitc-1
  framework:
    type: esp-idf

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_key

sensor:
  - platform: dht
    pin: GPIO4
    model: DHT22
    temperature:
      name: "Bedroom Temperature"
    humidity:
      name: "Bedroom Humidity"
```

### Smart Switch

```yaml
esphome_swift:
  name: smart_switch
  friendly_name: "Smart Switch"

esp32:
  board: esp32-c3-devkitm-1
  framework:
    type: esp-idf

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_key

switch:
  - platform: gpio
    pin: GPIO5
    name: "Light Switch"
    restore_mode: RESTORE_DEFAULT_OFF

binary_sensor:
  - platform: gpio
    pin:
      number: GPIO9
      mode: INPUT_PULLUP
      inverted: true
    name: "Light Button"
    # Note: Automation actions like on_press are planned for future releases
```