import Foundation
import Vapor
import ESPHomeSwiftCore

/// Web dashboard for monitoring and managing ESPHome Swift devices
public class WebDashboard {
    private let app: Application
    private let logger = Logger(label: "WebDashboard")
    
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
                    h1 { margin: 0; color: #333; }
                    h2 { color: #666; margin-top: 0; }
                    .device-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
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
                    </div>
                    
                    <div class="card">
                        <h2>📱 Connected Devices</h2>
                        <div class="device-grid">
                            <div class="card">
                                <h3>Example Device</h3>
                                <p><span class="status offline">OFFLINE</span></p>
                                <p>No devices connected yet</p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="card">
                        <h2>🛠️ Quick Actions</h2>
                        <p>• <a href="/api/devices">View API</a></p>
                        <p>• <a href="/logs">View Logs</a></p>
                        <p>• <a href="/config">Configuration</a></p>
                    </div>
                </div>
            </body>
            </html>
            """
        }
        
        // API routes
        app.grouped("api").group("devices") { devices in
            devices.get { req in
                return DeviceListResponse(
                    devices: [],
                    total: 0,
                    online: 0
                )
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
struct DeviceInfo: Content {
    let name: String
    let friendlyName: String
    let board: String
    let ipAddress: String?
    let status: DeviceStatus
    let lastSeen: Date
    let version: String
}

/// Device status enumeration
enum DeviceStatus: String, Content {
    case online = "online"
    case offline = "offline"
    case updating = "updating"
    case error = "error"
}

/// API response for device list
struct DeviceListResponse: Content {
    let devices: [DeviceInfo]
    let total: Int
    let online: Int
}