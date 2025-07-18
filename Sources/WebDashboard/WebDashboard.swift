import Foundation
import Vapor
import ESPHomeSwiftCore

/// Web dashboard for monitoring and managing ESPHome Swift devices
public class WebDashboard {
    private let app: Application
    private let logger = Logger(label: "WebDashboard")
    private let deviceManager = DeviceManager()
    
    public init() throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        app = Application(env)
        try configure(app)
    }
    
    deinit {
        // Synchronous shutdown for deinit
        app.shutdown()
    }
    
    /// Start the web server
    public func start(port: Int = 8080) async throws {
        app.http.server.configuration.port = port
        logger.info("Web dashboard starting on port \(port)")
        
        try await app.startup()
        
        if let running = app.running {
            try await running.onStop.get()
        }
    }
    
    /// Stop the web server
    public func stop() async throws {
        try await app.asyncShutdown()
    }
    
    /// Configure routes and middleware
    private func configure(_ app: Application) throws {
        // Configure middleware
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
        
        // Configure routes
        app.get { req in
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <title>ESPHome Swift Dashboard</title>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
                    .container { max-width: 1200px; margin: 0 auto; }
                    .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                    .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                    .status { display: inline-block; padding: 4px 8px; border-radius: 4px; color: white; font-size: 12px; font-weight: bold; }
                    .status.online { background: #28a745; }
                    .status.offline { background: #dc3545; }
                    .status.updating { background: #ffc107; color: #000; }
                    h1 { margin: 0; color: #333; }
                    h2 { color: #666; margin-top: 0; }
                    .device-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; }
                    .device-card { border: 1px solid #ddd; padding: 15px; border-radius: 8px; }
                    .device-header { display: flex; justify-content: between; align-items: center; margin-bottom: 10px; }
                    .device-name { font-weight: bold; color: #333; }
                    .entity-grid { display: grid; gap: 10px; margin-top: 10px; }
                    .entity { display: flex; justify-content: between; align-items: center; padding: 8px; background: #f8f9fa; border-radius: 4px; }
                    .entity-name { font-weight: 500; }
                    .entity-value { color: #666; }
                    .control-btn { background: #007bff; color: white; border: none; padding: 4px 8px; border-radius: 4px; cursor: pointer; }
                    .control-btn:hover { background: #0056b3; }
                    .control-btn.on { background: #28a745; }
                    .add-device { margin-bottom: 20px; }
                    .add-device input { padding: 8px; margin-right: 10px; border: 1px solid #ddd; border-radius: 4px; }
                    .add-device button { padding: 8px 16px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
                    .loading { color: #666; font-style: italic; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🏠 ESPHome Swift Dashboard</h1>
                        <p>Monitor and manage your ESPHome Swift devices</p>
                    </div>
                    
                    <div class="card">
                        <h2>📊 System Status</h2>
                        <p><span class="status online">RUNNING</span> Dashboard is operational</p>
                        <p>Version: 0.1.0</p>
                        <p id="device-stats" class="loading">Loading device statistics...</p>
                    </div>
                    
                    <div class="card">
                        <h2>📱 Connected Devices</h2>
                        <div class="add-device">
                            <input type="text" id="device-host" placeholder="Device IP address (e.g., 192.168.1.100)" style="width: 250px;">
                            <input type="number" id="device-port" placeholder="Port (6053)" value="6053" style="width: 80px;">
                            <button onclick="addDevice()">Add Device</button>
                        </div>
                        <div id="devices-container" class="device-grid">
                            <div class="loading">Discovering devices...</div>
                        </div>
                    </div>
                    
                    <div class="card">
                        <h2>🛠️ Quick Actions</h2>
                        <p>• <a href="/api/devices" target="_blank">View Devices API</a></p>
                        <p>• <a href="/logs">View Logs</a></p>
                        <p>• <a href="/config">Configuration</a></p>
                        <p>• <button onclick="refreshDevices()" class="control-btn">Refresh Devices</button></p>
                    </div>
                </div>
                
                <script>
                    let devices = [];
                    
                    // Load devices on page load
                    window.onload = function() {
                        loadDevices();
                        // Refresh every 30 seconds
                        setInterval(loadDevices, 30000);
                    };
                    
                    async function loadDevices() {
                        try {
                            const response = await fetch('/api/devices');
                            const data = await response.json();
                            devices = data.devices;
                            
                            updateDeviceStats(data);
                            renderDevices(data.devices);
                        } catch (error) {
                            console.error('Failed to load devices:', error);
                            document.getElementById('devices-container').innerHTML = '<div class="loading">Failed to load devices. Check console for details.</div>';
                        }
                    }
                    
                    function updateDeviceStats(data) {
                        const statsElement = document.getElementById('device-stats');
                        statsElement.innerHTML = `Total: ${data.total} | Online: ${data.online} | Offline: ${data.total - data.online}`;
                        statsElement.className = '';
                    }
                    
                    function renderDevices(devices) {
                        const container = document.getElementById('devices-container');
                        
                        if (devices.length === 0) {
                            container.innerHTML = '<div class="device-card"><p>No devices discovered yet. Use the "Add Device" form above to manually add devices.</p></div>';
                            return;
                        }
                        
                        container.innerHTML = devices.map(device => `
                            <div class="device-card">
                                <div class="device-header">
                                    <div>
                                        <div class="device-name">${device.friendlyName || device.name}</div>
                                        <div style="font-size: 12px; color: #666;">${device.ipAddress} • ${device.board}</div>
                                    </div>
                                    <span class="status ${device.status}">${device.status.toUpperCase()}</span>
                                </div>
                                <div style="font-size: 12px; color: #666; margin-bottom: 10px;">
                                    Version: ${device.version} | Last seen: ${new Date(device.lastSeen).toLocaleTimeString()}
                                </div>
                                <div id="entities-${device.name}" class="entity-grid">
                                    <div class="loading">Loading entities...</div>
                                </div>
                                <div style="margin-top: 10px;">
                                    <button onclick="loadDeviceDetails('${device.name}')" class="control-btn">Refresh</button>
                                    <button onclick="removeDevice('${device.name}')" class="control-btn" style="background: #dc3545; margin-left: 5px;">Remove</button>
                                </div>
                            </div>
                        `).join('');
                        
                        // Load details for each device
                        devices.forEach(device => loadDeviceDetails(device.name));
                    }
                    
                    async function loadDeviceDetails(deviceId) {
                        try {
                            const response = await fetch(`/api/devices/${deviceId}`);
                            const data = await response.json();
                            renderDeviceEntities(deviceId, data.entities);
                        } catch (error) {
                            console.error(`Failed to load details for ${deviceId}:`, error);
                            document.getElementById(`entities-${deviceId}`).innerHTML = '<div style="color: #dc3545;">Failed to load entities</div>';
                        }
                    }
                    
                    function renderDeviceEntities(deviceId, entities) {
                        const container = document.getElementById(`entities-${deviceId}`);
                        
                        if (entities.length === 0) {
                            container.innerHTML = '<div style="color: #666;">No entities found</div>';
                            return;
                        }
                        
                        container.innerHTML = entities.map(entity => {
                            const isControllable = entity.type === 'switch' || entity.type === 'light';
                            const stateDisplay = entity.state ? entity.state.displayValue || 'N/A' : 'N/A';
                            
                            let controlHtml = '';
                            if (isControllable) {
                                const isOn = entity.state && (entity.state.switch?.value || entity.state.light?.isOn);
                                controlHtml = `<button onclick="toggleEntity('${deviceId}', '${entity.id}', '${entity.type}', ${!isOn})" 
                                                     class="control-btn ${isOn ? 'on' : ''}">${isOn ? 'ON' : 'OFF'}</button>`;
                            }
                            
                            return `
                                <div class="entity">
                                    <div>
                                        <div class="entity-name">${entity.name}</div>
                                        <div style="font-size: 11px; color: #999;">${entity.type}${entity.deviceClass ? ' • ' + entity.deviceClass : ''}</div>
                                    </div>
                                    <div style="display: flex; align-items: center; gap: 10px;">
                                        <span class="entity-value">${stateDisplay}${entity.unitOfMeasurement || ''}</span>
                                        ${controlHtml}
                                    </div>
                                </div>
                            `;
                        }).join('');
                    }
                    
                    async function toggleEntity(deviceId, entityId, entityType, newState) {
                        try {
                            const response = await fetch(`/api/control/${deviceId}/${entityType}/${entityId}`, {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify(entityType === 'switch' ? { state: newState } : { isOn: newState })
                            });
                            
                            if (response.ok) {
                                // Refresh device details after a short delay
                                setTimeout(() => loadDeviceDetails(deviceId), 500);
                            } else {
                                console.error('Failed to control entity:', await response.text());
                            }
                        } catch (error) {
                            console.error('Failed to control entity:', error);
                        }
                    }
                    
                    async function addDevice() {
                        const host = document.getElementById('device-host').value.trim();
                        const port = parseInt(document.getElementById('device-port').value) || 6053;
                        
                        if (!host) {
                            alert('Please enter a device IP address');
                            return;
                        }
                        
                        try {
                            const response = await fetch('/api/devices/add', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ host, port })
                            });
                            
                            if (response.ok) {
                                document.getElementById('device-host').value = '';
                                document.getElementById('device-port').value = '6053';
                                loadDevices(); // Refresh the list
                            } else {
                                const error = await response.text();
                                alert(`Failed to add device: ${error}`);
                            }
                        } catch (error) {
                            alert(`Failed to add device: ${error.message}`);
                        }
                    }
                    
                    async function removeDevice(deviceId) {
                        if (!confirm(`Remove device "${deviceId}"?`)) return;
                        
                        try {
                            const response = await fetch(`/api/devices/${deviceId}`, { method: 'DELETE' });
                            if (response.ok) {
                                loadDevices(); // Refresh the list
                            } else {
                                alert('Failed to remove device');
                            }
                        } catch (error) {
                            alert(`Failed to remove device: ${error.message}`);
                        }
                    }
                    
                    function refreshDevices() {
                        loadDevices();
                    }
                </script>
            </body>
            </html>
            """
        }
        
        // API routes
        app.grouped("api").group("devices") { devices in
            // Get all devices
            devices.get { [weak self] req in
                guard let self = self else {
                    throw Abort(.internalServerError, reason: "Dashboard not available")
                }
                
                let stats = self.deviceManager.deviceStats
                let deviceInfos = self.deviceManager.discoveredDevices.map { device in
                    WebDashboardDeviceInfo(
                        name: device.name,
                        friendlyName: device.friendlyName,
                        board: device.board,
                        ipAddress: device.host,
                        status: device.status,
                        lastSeen: device.lastSeen,
                        version: device.version
                    )
                }
                
                return DeviceListResponse(
                    devices: deviceInfos,
                    total: stats.total,
                    online: stats.online
                )
            }
            
            // Get specific device details
            devices.get(":deviceId") { [weak self] req in
                guard let self = self else {
                    throw Abort(.internalServerError, reason: "Dashboard not available")
                }
                
                guard let deviceId = req.parameters.get("deviceId") else {
                    throw Abort(.badRequest, reason: "Device ID required")
                }
                
                guard let device = self.deviceManager.getDevice(deviceId) else {
                    throw Abort(.notFound, reason: "Device not found")
                }
                
                return DeviceDetailResponse(
                    device: WebDashboardDeviceInfo(
                        name: device.name,
                        friendlyName: device.friendlyName,
                        board: device.board,
                        ipAddress: device.host,
                        status: device.status,
                        lastSeen: device.lastSeen,
                        version: device.version
                    ),
                    entities: device.entities
                )
            }
            
            // Add device manually
            devices.post("add") { [weak self] req in
                guard let self = self else {
                    throw Abort(.internalServerError, reason: "Dashboard not available")
                }
                
                let addRequest = try req.content.decode(AddDeviceRequest.self)
                
                try await self.deviceManager.addDevice(host: addRequest.host, port: addRequest.port ?? 6053)
                
                return AddDeviceResponse(success: true, message: "Device added successfully")
            }
            
            // Remove device
            devices.delete(":deviceId") { [weak self] req in
                guard let self = self else {
                    throw Abort(.internalServerError, reason: "Dashboard not available")
                }
                
                guard let deviceId = req.parameters.get("deviceId") else {
                    throw Abort(.badRequest, reason: "Device ID required")
                }
                
                self.deviceManager.removeDevice(deviceId)
                
                return RemoveDeviceResponse(success: true, message: "Device removed")
            }
        }
        
        // Device control API
        app.grouped("api", "control").group(":deviceId") { control in
            // Control switch
            control.post("switch", ":entityId") { [weak self] req in
                guard let self = self else {
                    throw Abort(.internalServerError, reason: "Dashboard not available")
                }
                
                guard let deviceId = req.parameters.get("deviceId"),
                      let entityId = req.parameters.get("entityId") else {
                    throw Abort(.badRequest, reason: "Device ID and Entity ID required")
                }
                
                let controlRequest = try req.content.decode(SwitchControlRequest.self)
                
                guard let device = self.deviceManager.getDevice(deviceId),
                      let entity = device.entities.first(where: { $0.id == entityId }),
                      entity.type == .switch else {
                    throw Abort(.notFound, reason: "Switch entity not found")
                }
                
                try await device.connection?.sendSwitchCommand(key: entity.key, state: controlRequest.state)
                
                return ControlResponse(success: true, message: "Switch command sent")
            }
            
            // Control light
            control.post("light", ":entityId") { [weak self] req in
                guard let self = self else {
                    throw Abort(.internalServerError, reason: "Dashboard not available")
                }
                
                guard let deviceId = req.parameters.get("deviceId"),
                      let entityId = req.parameters.get("entityId") else {
                    throw Abort(.badRequest, reason: "Device ID and Entity ID required")
                }
                
                let controlRequest = try req.content.decode(LightControlRequest.self)
                
                guard let device = self.deviceManager.getDevice(deviceId),
                      let entity = device.entities.first(where: { $0.id == entityId }),
                      entity.type == .light else {
                    throw Abort(.notFound, reason: "Light entity not found")
                }
                
                try await device.connection?.sendLightCommand(
                    key: entity.key,
                    isOn: controlRequest.isOn,
                    brightness: controlRequest.brightness,
                    red: controlRequest.red,
                    green: controlRequest.green,
                    blue: controlRequest.blue
                )
                
                return ControlResponse(success: true, message: "Light command sent")
            }
        }
        
        app.get("logs") { req in
            return "📄 Logs will be displayed here in a future version"
        }
        
        app.get("config") { req in
            return "⚙️ Configuration interface coming soon"
        }
    }
}

/// Device information for API responses
struct WebDashboardDeviceInfo: Content {
    let name: String
    let friendlyName: String
    let board: String
    let ipAddress: String?
    let status: DeviceStatus
    let lastSeen: Date
    let version: String
}

/// Device status enumeration
public enum DeviceStatus: String, Content {
    case online = "online"
    case offline = "offline"
    case updating = "updating"
    case error = "error"
}

/// API response for device list
struct DeviceListResponse: Content {
    let devices: [WebDashboardDeviceInfo]
    let total: Int
    let online: Int
}

/// API response for device details
struct DeviceDetailResponse: Content {
    let device: WebDashboardDeviceInfo
    let entities: [DeviceEntity]
}

/// Request to add a device manually
struct AddDeviceRequest: Content {
    let host: String
    let port: Int?
}

/// Response for add device request
struct AddDeviceResponse: Content {
    let success: Bool
    let message: String
}

/// Response for remove device request
struct RemoveDeviceResponse: Content {
    let success: Bool
    let message: String
}

/// Request to control a switch
struct SwitchControlRequest: Content {
    let state: Bool
}

/// Request to control a light
struct LightControlRequest: Content {
    let isOn: Bool
    let brightness: Float?
    let red: Float?
    let green: Float?
    let blue: Float?
}

/// Generic control response
struct ControlResponse: Content {
    let success: Bool
    let message: String
}