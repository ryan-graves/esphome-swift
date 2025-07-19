import Foundation

/// Development configuration for WebDashboard
public struct DevelopmentConfiguration {
    
    /// Whether to use mock data for development/testing
    public static var useMockData: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ESPHOME_SWIFT_USE_MOCK_DATA"] == "true"
        #else
        return false
        #endif
    }
    
    /// Whether to enable device discovery
    public static var enableDeviceDiscovery: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ESPHOME_SWIFT_ENABLE_DISCOVERY"] == "true"
        #else
        return true
        #endif
    }
    
    /// Whether to enable verbose logging
    public static var verboseLogging: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ESPHOME_SWIFT_VERBOSE"] == "true"
        #else
        return false
        #endif
    }
    
    /// Mock device refresh interval (in seconds)
    public static var mockRefreshInterval: Double {
        #if DEBUG
        if let intervalString = ProcessInfo.processInfo.environment["ESPHOME_SWIFT_MOCK_REFRESH_INTERVAL"],
           let interval = Double(intervalString) {
            return interval
        }
        return 30.0
        #else
        return 30.0
        #endif
    }
    
    /// Whether to simulate network delays for testing
    public static var simulateNetworkDelay: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ESPHOME_SWIFT_SIMULATE_DELAY"] == "true"
        #else
        return false
        #endif
    }
    
    /// Simulated network delay in milliseconds
    public static var networkDelayMs: UInt64 {
        #if DEBUG
        if let delayString = ProcessInfo.processInfo.environment["ESPHOME_SWIFT_NETWORK_DELAY_MS"],
           let delay = UInt64(delayString) {
            return delay
        }
        return 100
        #else
        return 0
        #endif
    }
}

/// Mock data provider for development and testing
public struct MockDataProvider {
    
    /// Generate mock device info
    public static func mockDeviceInfo(for host: String) -> DeviceConnectionInfo {
        let deviceName = extractDeviceName(from: host)
        return DeviceConnectionInfo(
            name: deviceName,
            friendlyName: "\(deviceName.capitalized) Device",
            board: "esp32-c6-devkitc-1",
            version: "1.0.0-mock",
            macAddress: generateMockMacAddress(for: host),
            compilationTime: Date().addingTimeInterval(-TimeInterval.random(in: 0 ... 86400))
        )
    }
    
    /// Generate mock entities for a device
    public static func mockEntities(for deviceName: String) -> [DeviceEntity] {
        let baseKey = UInt32(deviceName.hash) & 0xFFFF
        
        return [
            DeviceEntity(
                id: "temperature",
                key: baseKey + 1,
                name: "Temperature",
                type: .sensor,
                deviceClass: "temperature",
                unitOfMeasurement: "°C",
                icon: "mdi:thermometer",
                state: .sensor(value: Float.random(in: 15 ... 35), missing: false)
            ),
            DeviceEntity(
                id: "humidity",
                key: baseKey + 2,
                name: "Humidity",
                type: .sensor,
                deviceClass: "humidity",
                unitOfMeasurement: "%",
                icon: "mdi:water-percent",
                state: .sensor(value: Float.random(in: 30 ... 80), missing: false)
            ),
            DeviceEntity(
                id: "motion",
                key: baseKey + 3,
                name: "Motion Sensor",
                type: .binarySensor,
                deviceClass: "motion",
                icon: "mdi:motion-sensor",
                state: .binarySensor(value: Bool.random(), missing: false)
            ),
            DeviceEntity(
                id: "relay_switch",
                key: baseKey + 4,
                name: "Relay Switch",
                type: .switch,
                icon: "mdi:power-socket-eu",
                state: .switch(value: Bool.random())
            ),
            DeviceEntity(
                id: "status_light",
                key: baseKey + 5,
                name: "Status Light",
                type: .light,
                icon: "mdi:lightbulb",
                state: .light(
                    isOn: Bool.random(),
                    brightness: Float.random(in: 0 ... 1),
                    red: Float.random(in: 0 ... 1),
                    green: Float.random(in: 0 ... 1),
                    blue: Float.random(in: 0 ... 1)
                )
            )
        ]
    }
    
    /// Extract device name from host
    private static func extractDeviceName(from host: String) -> String {
        if host.contains(".local") {
            return String(host.prefix(while: { $0 != "." }))
        }
        let cleanHost = host.replacingOccurrences(of: ".", with: "-")
        return "device-\(cleanHost)"
    }
    
    /// Generate a consistent mock MAC address for a host
    private static func generateMockMacAddress(for host: String) -> String {
        let hash = host.hash
        let bytes = [
            0xAA,
            UInt8((hash >> 24) & 0xFF),
            UInt8((hash >> 16) & 0xFF),
            UInt8((hash >> 8) & 0xFF),
            UInt8(hash & 0xFF),
            0xFF
        ]
        return bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
}

/// Network simulation utilities for testing
public struct NetworkSimulator {
    
    /// Simulate network delay if enabled
    public static func simulateDelay() async {
        guard DevelopmentConfiguration.simulateNetworkDelay else { return }
        
        let delayNs = DevelopmentConfiguration.networkDelayMs * 1_000_000
        try? await Task.sleep(nanoseconds: delayNs)
    }
    
    /// Simulate network failure randomly
    public static func shouldSimulateFailure() -> Bool {
        #if DEBUG
        guard DevelopmentConfiguration.useMockData else { return false }
        return Double.random(in: 0 ... 1) < 0.05 // 5% failure rate
        #else
        return false
        #endif
    }
}