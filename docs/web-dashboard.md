---
layout: default
title: Web Dashboard
---

# Web Dashboard

ESPHome Swift includes a powerful built-in web dashboard for monitoring and controlling your devices in real-time. The dashboard provides a modern, responsive interface for managing your entire ESPHome Swift ecosystem.

## Overview

The web dashboard serves as a central control hub where you can:

- **Discover and manage devices** automatically via mDNS or manually by IP
- **Monitor real-time status** of all sensors, switches, and lights
- **Control devices remotely** through an intuitive web interface
- **View device information** including board type, version, and connectivity status
- **Track device history** with last seen timestamps and connection status

## Starting the Dashboard

### Basic Usage

```bash
# Start the dashboard with default settings
esphome-swift dashboard

# The dashboard will be available at http://localhost:8080
```

### Advanced Options

```bash
# Start on a custom port
esphome-swift dashboard --port 8080

# Start with verbose logging
esphome-swift dashboard --verbose

# Start on all interfaces (accessible from other devices)
esphome-swift dashboard --host 0.0.0.0
```

## Dashboard Interface

### Main Dashboard View

The dashboard provides a clean, modern interface with several key sections:

#### System Status
- **Running Status**: Shows if the dashboard service is operational
- **Version Information**: Current ESPHome Swift version
- **Device Statistics**: Total devices, online count, offline count

#### Device Grid
- **Real-time Discovery**: Devices appear automatically as they're discovered
- **Status Indicators**: Online (green), Offline (red), Updating (yellow)
- **Device Information**: Name, IP address, board type, version
- **Last Seen**: Timestamp of last successful communication

#### Quick Actions
- **Refresh Devices**: Manually trigger device discovery
- **API Access**: Direct links to REST API endpoints
- **Logs**: View system logs (coming soon)
- **Configuration**: Access settings interface (coming soon)

### Device Details

Click on any device to view detailed information:

#### Device Information
- **Name & Friendly Name**: Device identification
- **Board Type**: ESP32 variant (C3, C6, H2, P4)
- **IP Address**: Current network address
- **MAC Address**: Hardware identifier
- **Version**: Firmware version
- **Connection Status**: Real-time connectivity state

#### Entity Control
- **Sensors**: Live readings with units (°C, %, etc.)
- **Binary Sensors**: ON/OFF state indicators
- **Switches**: Toggle controls for relays and outputs
- **Lights**: Power and brightness controls

## Device Management

### Automatic Discovery

The dashboard automatically discovers ESPHome Swift devices on your network using mDNS:

- Devices announce themselves as `_esphomelib._tcp` services
- Discovery runs continuously in the background
- New devices appear within 30 seconds of coming online
- Device list refreshes every 30 seconds automatically

### Manual Device Addition

If automatic discovery doesn't work or for devices on different subnets:

1. **Click "Add Device"** in the device management section
2. **Enter IP Address**: Use the device's current IP (check your router or use `ping device-name.local`)
3. **Set Port**: Use 6053 (default ESPHome native API port) unless changed in configuration
4. **Click "Add Device"**: The dashboard will attempt to connect and retrieve device information

### Device Operations

#### Refresh Device
- Updates device status and entity states
- Retrieves latest sensor readings
- Checks connection status

#### Remove Device
- Removes device from the dashboard registry
- Does not affect the physical device
- Device may reappear if auto-discovery finds it again

## Real-time Controls

### Switch Control
- **Toggle Switches**: Click ON/OFF buttons to control relays
- **Instant Feedback**: Button state reflects actual device state
- **Error Handling**: Failed commands show error messages

### Light Control
- **Power Control**: Turn lights on/off with dedicated buttons
- **Brightness Control**: Adjust brightness for dimmable lights (if supported)
- **Color Control**: RGB color picker for color lights (if supported)

### Sensor Monitoring
- **Live Values**: Sensor readings update automatically
- **Units**: Proper unit display (°C, °F, %, lux, etc.)
- **Device Classes**: Temperature, humidity, illuminance indicators
- **Missing Data**: Clear indication when sensors are offline

## API Integration

The dashboard provides RESTful API endpoints for programmatic access:

### Device Endpoints

```bash
# Get all devices
GET /api/devices

# Get specific device details
GET /api/devices/{deviceId}

# Add device manually
POST /api/devices/add
{
  "host": "192.168.1.100",
  "port": 6053
}

# Remove device
DELETE /api/devices/{deviceId}
```

### Control Endpoints

```bash
# Control switch
POST /api/control/{deviceId}/switch/{entityId}
{
  "state": true
}

# Control light
POST /api/control/{deviceId}/light/{entityId}
{
  "isOn": true,
  "brightness": 0.8,
  "red": 1.0,
  "green": 0.0,
  "blue": 0.0
}
```

### Response Format

All API responses follow a consistent JSON format:

```json
{
  "devices": [
    {
      "name": "living-room-sensor",
      "friendlyName": "Living Room Sensor",
      "board": "esp32-c6-devkitc-1",
      "ipAddress": "192.168.1.100",
      "status": "online",
      "lastSeen": "2025-01-20T10:30:00Z",
      "version": "1.0.0"
    }
  ],
  "total": 1,
  "online": 1
}
```

## Security Considerations

### Network Access
- **Local Network Only**: Dashboard binds to localhost by default
- **Custom Binding**: Use `--host 0.0.0.0` to allow external access
- **No Authentication**: Currently no built-in authentication (planned for future)

### Device Communication
- **ESPHome Native API**: Secure, encrypted communication with devices
- **No Cloud Dependency**: All communication stays on local network
- **API Keys**: Devices can require API keys for enhanced security

## Troubleshooting

### Device Not Appearing

1. **Check Network**: Ensure device and dashboard are on same network
2. **Verify mDNS**: Some networks block mDNS multicast traffic
3. **Add Manually**: Use "Add Device" with IP address
4. **Check Logs**: Start dashboard with `--verbose` for detailed logging

### Connection Failures

1. **Check IP Address**: Device IP may have changed (DHCP)
2. **Verify Port**: Ensure device is using port 6053 for native API
3. **API Configuration**: Check if device requires encryption key
4. **Firewall**: Ensure port 6053 is not blocked

### Dashboard Not Loading

1. **Port Conflicts**: Try different port with `--port 8081`
2. **Browser Cache**: Clear browser cache and reload
3. **JavaScript Errors**: Check browser console for errors
4. **Network Issues**: Verify dashboard is running and accessible

### Performance Issues

1. **Many Devices**: Dashboard performance degrades with 50+ devices
2. **Refresh Rate**: Reduce auto-refresh frequency in browser
3. **Device Load**: Heavily loaded devices may respond slowly
4. **Network Latency**: High latency affects real-time updates

## Integration Examples

### Home Assistant
The web dashboard complements Home Assistant integration:

```yaml
# Use dashboard for device management
# Use Home Assistant for automation
automation:
  - alias: "Dashboard Control"
    trigger:
      platform: webhook
      webhook_id: esphome_swift_dashboard
    action:
      service: light.toggle
      entity_id: light.living_room_switch
```

### Third-party Tools
Access the REST API from any HTTP client:

```bash
# curl examples
curl http://localhost:8080/api/devices
curl -X POST http://localhost:8080/api/control/device1/switch/relay1 \
     -H "Content-Type: application/json" \
     -d '{"state": true}'
```

```python
# Python example
import requests

# Get device list
response = requests.get('http://localhost:8080/api/devices')
devices = response.json()['devices']

# Control a switch
requests.post(
    'http://localhost:8080/api/control/device1/switch/relay1',
    json={'state': True}
)
```

## Future Enhancements

Planned features for upcoming releases:

- **User Authentication**: Login system with role-based access
- **Device Groups**: Organize devices by room or function
- **Historical Data**: Sensor data logging and visualization
- **Automation Rules**: Simple automation without Home Assistant
- **Mobile App**: Companion mobile application
- **WebSocket Updates**: Real-time updates without polling
- **Configuration Editor**: Edit device YAML configurations through web interface
- **Backup/Restore**: Device configuration backup and restore
- **Firmware Updates**: OTA firmware update management
- **Advanced Logging**: Centralized log collection and analysis

## Contributing

The web dashboard is part of the ESPHome Swift project. Contributions are welcome:

- **Bug Reports**: Report issues on GitHub
- **Feature Requests**: Suggest new dashboard features
- **Pull Requests**: Submit improvements and fixes
- **Documentation**: Help improve this documentation

See the [Contributing Guide](../CONTRIBUTING.md) for details on development setup and guidelines.