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
- `esp32-c6-devkitc-1` - ESP32-C6 DevKit (Matter/Thread capable)
- `esp32-c6-devkitm-1` - ESP32-C6 DevKit (Matter/Thread capable)
- `esp32-h2-devkitc-1` - ESP32-H2 DevKit (Matter/Thread capable)
- `esp32-h2-devkitm-1` - ESP32-H2 DevKit (Matter/Thread capable)
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

### matter

Enable Matter protocol support for interoperable smart home devices (ESP32-C6/H2 only).

```yaml
matter:
  enabled: true                    # Required: Enable Matter support
  device_type: temperature_sensor  # Required: Matter device type
  vendor_id: 0xFFF1               # Optional: Vendor ID (test ID default)
  product_id: 0x8000              # Optional: Product ID
  
  # Device commissioning configuration
  commissioning:
    discriminator: 3840           # Optional: 12-bit discriminator
    passcode: 20202021           # Optional: Setup passcode
    manual_pairing_code: "12345-67890"  # Optional: Manual code
    qr_code_payload: "MT:..."    # Optional: QR code payload
  
  # Thread network configuration (ESP32-C6/H2)
  thread:
    enabled: true                 # Optional: Enable Thread networking
    network_name: "Home Network"  # Optional: Thread network name
    channel: 15                   # Optional: 802.15.4 channel (11-26)
    pan_id: 0x1234               # Optional: PAN ID
    ext_pan_id: "1234567890ABCDEF1234567890ABCDEF"  # Optional: Extended PAN ID
    network_key: "FEDCBA0987654321FEDCBA0987654321"  # Optional: Network key
    dataset: "0e080000..."        # Optional: Complete operational dataset
  
  # Network transport configuration
  network:
    transport: wifi               # Required: wifi/thread/ethernet
    ipv6_enabled: true           # Optional: Enable IPv6
    mdns:
      enabled: true              # Optional: Enable mDNS
      hostname: "my-device"      # Optional: Custom hostname
      services: ["_matter._tcp"] # Optional: Additional services
```

**Matter Device Types:**

*Lighting:*
- `on_off_light` - Simple on/off light
- `dimmable_light` - Dimmable light with level control
- `color_temperature_light` - Tunable white light
- `extended_color_light` - Full color RGB light

*Switches:*
- `on_off_switch` - Simple on/off switch
- `dimmer_switch` - Dimmer switch with level control
- `color_dimmer_switch` - Color dimmer switch
- `generic_switch` - Generic switch device

*Sensors:*
- `temperature_sensor` - Temperature measurement
- `humidity_sensor` - Humidity measurement
- `occupancy_sensor` - Motion/occupancy detection
- `contact_sensor` - Door/window contact
- `light_sensor` - Light level measurement
- `pressure_sensor` - Pressure measurement
- `flow_sensor` - Flow measurement
- `air_quality_sensor` - Air quality monitoring

*Appliances:*
- `smart_plug` - Smart outlet/plug
- `door_lock` - Electronic door lock
- `thermostat` - Climate control device
- `fan` - Fan control device
- `window_covering` - Blinds/shades control

**Transport Options:**
- `wifi` - Standard WiFi connectivity (all ESP32 boards)
- `thread` - Thread mesh networking (ESP32-C6/H2 only)
- `ethernet` - Wired ethernet (not currently supported)

**Thread Configuration Notes:**
- Thread requires ESP32-C6 or ESP32-H2 boards
- Channel range: 11-26 (802.15.4)
- PAN ID range: 0x0000-0xFFFE
- Network keys and Extended PAN IDs must be 32 hex characters
- Operational dataset is a complete Thread network configuration

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