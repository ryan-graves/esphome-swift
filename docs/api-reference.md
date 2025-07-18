---
layout: default
title: API Reference
---

# ESPHome Swift API Reference

ESPHome Swift generates firmware with a built-in native API server that provides real-time communication with Home Assistant and other clients.

## Native API Server

The generated firmware includes a complete ESPHome-compatible native API server that enables:

- **Real-time state updates** from sensors and components
- **Device control** for switches, lights, and other actuators  
- **Home Assistant integration** with automatic discovery
- **State persistence** across client connections
- **Multi-client support** with state synchronization

### API Configuration

Add API support to your device configuration:

```yaml
esphome_swift:
  name: my_device
  
esp32:
  board: esp32-c6-devkitc-1
  
api:
  port: 6053        # Optional: Default is 6053
  password: "secret" # Optional: Authentication password
  
# Optional: Encryption (future feature)
# api:
#   encryption:
#     key: "base64-encoded-key"
```

### Generated API Features

The generated firmware automatically includes:

#### 1. Device Information
- Device name, MAC address, and board type
- ESPHome version compatibility
- Compilation timestamp and model information

#### 2. Component Discovery
- Automatic entity listing for all configured components
- Device class and capability reporting
- Unique ID generation for Home Assistant

#### 3. State Management
- **Real-time updates**: Components report state changes immediately
- **State persistence**: Last known states maintained across connections
- **Missing state handling**: Graceful handling of sensor failures
- **Bulk updates**: Initial state sync for new connections

#### 4. Supported Component Types

| Component Type | State Reporting | Commands | Features |
|---------------|-----------------|----------|----------|
| **Sensors** | ✅ Float values | ❌ Read-only | Missing state detection |
| **Binary Sensors** | ✅ On/Off state | ❌ Read-only | Device class support |
| **Switches** | ✅ On/Off state | ✅ Control | Restore mode support |
| **Lights** | ✅ Full state | ✅ Control | Brightness, RGB support |

### Protocol Details

ESPHome Swift implements the standard ESPHome native API protocol:

#### Connection Flow
1. **Hello Exchange**: Version and capability negotiation
2. **Authentication**: Password verification (if configured)
3. **Device Info**: Board and firmware details
4. **Entity Discovery**: Component listing and capabilities
5. **State Subscription**: Real-time updates begin

#### Message Types
- `HELLO_REQUEST/RESPONSE`: Initial handshake
- `CONNECT_REQUEST/RESPONSE`: Authentication  
- `DEVICE_INFO_REQUEST/RESPONSE`: Device details
- `LIST_ENTITIES_*`: Component discovery
- `SUBSCRIBE_STATES_REQUEST`: Enable state updates
- `*_STATE_RESPONSE`: Component state reporting
- `*_COMMAND_REQUEST`: Device control commands

### State Persistence Architecture

The API server maintains component state in memory:

```c
// Generated state management (simplified)
typedef struct {
    uint32_t key;           // Unique component identifier
    uint8_t type;           // Component type (sensor, switch, etc.)
    union {
        struct { float value; bool has_value; } sensor;
        struct { bool value; } switch_state;
        struct { bool on; float brightness; float r, g, b; } light;
    } state;
} component_state_t;
```

### Home Assistant Integration

Devices with API enabled automatically:

1. **Advertise via mDNS** for network discovery
2. **Provide device info** for automatic entity creation
3. **Report component states** with appropriate device classes
4. **Accept commands** for controllable components
5. **Maintain connections** with automatic reconnection

### Example Generated API Code

For a DHT22 temperature sensor, the generated firmware includes:

```c
// Temperature sensor API integration
static uint32_t dht_temperature_key = 12345;
static float dht_temperature_state = 0.0f;
static bool dht_temperature_has_state = false;

void dht_temperature_register_api() {
    api_register_sensor(dht_temperature_key, "Temperature", 
                       "dht_temperature", "temperature", "°C");
}

void dht_temperature_report_state(float value) {
    dht_temperature_state = value;
    dht_temperature_has_state = true;
    if (api_client_subscribed()) {
        api_send_sensor_state(dht_temperature_key, value, false);
    }
}
```

### Advanced Features

#### Multi-Component Support
- Up to 32 components per device (configurable)
- Efficient key-based state lookup
- Type-safe state management

#### Error Handling
- Graceful handling of missing sensors
- Network disconnection recovery
- Invalid command rejection

#### Performance Optimization
- Minimal memory footprint
- Efficient binary protocol
- Non-blocking operation

### Debugging API Communication

Enable debug logging in your ESP-IDF configuration:

```c
// In sdkconfig or menuconfig
CONFIG_LOG_DEFAULT_LEVEL_DEBUG=y
CONFIG_ESPHOME_API_LOG_LEVEL_DEBUG=y
```

View API server logs:
```bash
esphome-swift monitor my_device.yaml
```

### Integration Examples

#### Home Assistant
Devices appear automatically in the Integrations panel. Configure via UI or add manually:

```yaml
# configuration.yaml
esphome:
  dashboard_use_ping: true
```

#### Custom Clients
Connect using the ESPHome API protocol:

```python
import aioesphomeapi

async def connect_to_device():
    api = aioesphomeapi.APIClient("192.168.1.100", 6053, "password")
    await api.connect()
    
    # Get device info
    device_info = await api.device_info()
    print(f"Connected to {device_info.name}")
    
    # Subscribe to states
    def on_state_update(state):
        print(f"State update: {state}")
    
    await api.subscribe_states(on_state_update)
```

## Future API Enhancements

Planned improvements include:

- **WebSocket support** for web dashboard integration
- **REST API endpoints** for simple HTTP access  
- **Bluetooth API** for local mobile access
- **Advanced encryption** with certificate support
- **API rate limiting** and access controls

The native API provides a solid foundation for all current and future communication needs with ESPHome Swift devices.