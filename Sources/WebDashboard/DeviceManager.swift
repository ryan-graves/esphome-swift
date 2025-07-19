import Foundation
import Network
import Logging
import ESPHomeSwiftCore

/// Device management system for discovering and tracking ESPHome Swift devices
public class DeviceManager: ObservableObject {
    private let logger = Logger(label: "DeviceManager")
    private var devices: [String: ManagedDevice] = [:]
    private var discoveryTimer: Timer?
    private var mdnsListener: NWListener?
    
    // Thread safety
    private let deviceAccessQueue = DispatchQueue(label: "DeviceManager.devices", qos: .userInitiated)
    private let concurrentRefreshQueue = DispatchQueue(
        label: "DeviceManager.refresh",
        qos: .utility,
        attributes: .concurrent
    )
    
    /// Discovered devices
    @Published public var discoveredDevices: [ManagedDevice] = []
    
    public init() {
        if DevelopmentConfiguration.enableDeviceDiscovery {
            startDeviceDiscovery()
            logger.info("DeviceManager initialized with discovery enabled")
        } else {
            logger.info("DeviceManager initialized (discovery disabled via configuration)")
        }
    }
    
    deinit {
        stopDeviceDiscovery()
    }
    
    /// Start mDNS discovery for ESPHome devices
    private func startDeviceDiscovery() {
        logger.info("Starting device discovery via mDNS")
        
        // Set up mDNS listener for _esphomelib._tcp services
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        do {
            mdnsListener = try NWListener(using: parameters)
            // Note: mDNS service discovery would use Network framework's NWBrowser
            // For now, we'll rely on manual device addition
            
            mdnsListener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            mdnsListener?.start(queue: .main)
            
            // Start periodic discovery refresh
            let refreshInterval = DevelopmentConfiguration.mockRefreshInterval
            discoveryTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
                self?.refreshDevices()
            }
            
        } catch {
            logger.error("Failed to start mDNS discovery: \\(error)")
        }
    }
    
    /// Stop device discovery
    private func stopDeviceDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        
        mdnsListener?.cancel()
        mdnsListener = nil
        
        logger.info("Device discovery stopped")
    }
    
    /// Handle new mDNS connection
    private func handleNewConnection(_ connection: NWConnection) {
        let endpoint = connection.endpoint
        if case .hostPort = endpoint {
            Task {
                await discoverDevice(from: endpoint)
            }
        }
    }
    
    /// Discover device information from endpoint
    private func discoverDevice(from endpoint: NWEndpoint) async {
        guard case .hostPort(let host, let port) = endpoint else { return }
        
        let hostString = "\(host)"
        let portInt = Int(port.rawValue)
        
        logger.info("Discovering device at \(hostString):\(portInt)")
        
        // Try to connect to the device's API
        do {
            let device = try await connectToDevice(host: hostString, port: portInt)
            addOrUpdateDevice(device)
        } catch {
            logger.warning("Failed to connect to device at \\(hostString): \\(error)")
        }
    }
    
    /// Connect to a device and retrieve its information
    private func connectToDevice(host: String, port: Int) async throws -> ManagedDevice {
        let connection = DeviceConnection(host: host, port: port)
        
        // Get device info via API
        let deviceInfo = try await connection.getDeviceInfo()
        let entities = try await connection.listEntities()
        
        return ManagedDevice(
            id: deviceInfo.name,
            name: deviceInfo.name,
            friendlyName: deviceInfo.friendlyName ?? deviceInfo.name,
            host: host,
            port: port,
            board: deviceInfo.board,
            version: deviceInfo.version,
            macAddress: deviceInfo.macAddress,
            status: .online,
            lastSeen: Date(),
            entities: entities,
            connection: connection
        )
    }
    
    /// Add or update a device in the registry
    private func addOrUpdateDevice(_ device: ManagedDevice) {
        deviceAccessQueue.sync {
            devices[device.id] = device
        }
        
        // Update published property on main queue
        Task { @MainActor in
            let allDevices = deviceAccessQueue.sync { Array(devices.values) }
            discoveredDevices = allDevices
        }
        
        logger.info("Device updated: \\(device.name) (\\(device.host))")
    }
    
    /// Refresh all known devices using structured concurrency
    private func refreshDevices() {
        Task {
            let currentDevices = deviceAccessQueue.sync { Array(devices.values) }
            
            await withTaskGroup(of: Void.self) { group in
                for device in currentDevices {
                    group.addTask { [weak self] in
                        await self?.refreshDevice(device)
                    }
                }
            }
        }
    }
    
    /// Refresh a specific device's status
    private func refreshDevice(_ device: ManagedDevice) async {
        do {
            // Try to ping the device
            let isOnline = try await device.connection?.ping() ?? false
            
            let updatedDevice = ManagedDevice(
                id: device.id,
                name: device.name,
                friendlyName: device.friendlyName,
                host: device.host,
                port: device.port,
                board: device.board,
                version: device.version,
                macAddress: device.macAddress,
                status: isOnline ? .online : .offline,
                lastSeen: isOnline ? Date() : device.lastSeen,
                entities: device.entities,
                connection: device.connection
            )
            
            addOrUpdateDevice(updatedDevice)
            
        } catch {
            logger.warning("Failed to refresh device \\(device.name): \\(error)")
            
            // Mark as offline
            let offlineDevice = ManagedDevice(
                id: device.id,
                name: device.name,
                friendlyName: device.friendlyName,
                host: device.host,
                port: device.port,
                board: device.board,
                version: device.version,
                macAddress: device.macAddress,
                status: .offline,
                lastSeen: device.lastSeen,
                entities: device.entities,
                connection: device.connection
            )
            
            addOrUpdateDevice(offlineDevice)
        }
    }
    
    /// Manually add a device by IP address
    public func addDevice(host: String, port: Int = 6053) async throws {
        logger.info("Manually adding device at \\(host):\\(port)")
        
        do {
            let device = try await connectToDevice(host: host, port: port)
            addOrUpdateDevice(device)
        } catch {
            logger.error("Failed to add device at \\(host): \\(error)")
            throw error
        }
    }
    
    /// Remove a device from the registry
    public func removeDevice(_ deviceId: String) {
        _ = deviceAccessQueue.sync {
            devices.removeValue(forKey: deviceId)
        }
        
        // Update published property on main queue
        Task { @MainActor in
            let allDevices = deviceAccessQueue.sync { Array(devices.values) }
            discoveredDevices = allDevices
        }
        
        logger.info("Device removed: \\(deviceId)")
    }
    
    /// Get device by ID
    public func getDevice(_ deviceId: String) -> ManagedDevice? {
        return deviceAccessQueue.sync {
            return devices[deviceId]
        }
    }
    
    /// Get all online devices
    public var onlineDevices: [ManagedDevice] {
        return discoveredDevices.filter { $0.status == .online }
    }
    
    /// Get device statistics
    public var deviceStats: DeviceStats {
        return DeviceStats(
            total: discoveredDevices.count,
            online: onlineDevices.count,
            offline: discoveredDevices.count - onlineDevices.count
        )
    }
}

/// Managed device with connection and state tracking
public struct ManagedDevice: Identifiable, Codable {
    public let id: String
    public let name: String
    public let friendlyName: String
    public let host: String
    public let port: Int
    public let board: String
    public let version: String
    public let macAddress: String
    public let status: DeviceStatus
    public let lastSeen: Date
    public let entities: [DeviceEntity]
    
    // Connection is not codable, managed separately
    var connection: DeviceConnection?
    
    public init(id: String, name: String, friendlyName: String, host: String, port: Int,
                board: String, version: String, macAddress: String, status: DeviceStatus,
                lastSeen: Date, entities: [DeviceEntity], connection: DeviceConnection?) {
        self.id = id
        self.name = name
        self.friendlyName = friendlyName
        self.host = host
        self.port = port
        self.board = board
        self.version = version
        self.macAddress = macAddress
        self.status = status
        self.lastSeen = lastSeen
        self.entities = entities
        self.connection = connection
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, friendlyName, host, port, board, version, macAddress, status, lastSeen, entities
    }
}

/// Device entity (sensor, switch, etc.)
public struct DeviceEntity: Identifiable, Codable, Sendable {
    public let id: String
    public let key: UInt32
    public let name: String
    public let type: EntityType
    public let deviceClass: String?
    public let unitOfMeasurement: String?
    public let icon: String?
    public var state: EntityState?
    
    public init(id: String, key: UInt32, name: String, type: EntityType,
                deviceClass: String? = nil, unitOfMeasurement: String? = nil,
                icon: String? = nil, state: EntityState? = nil) {
        self.id = id
        self.key = key
        self.name = name
        self.type = type
        self.deviceClass = deviceClass
        self.unitOfMeasurement = unitOfMeasurement
        self.icon = icon
        self.state = state
    }
}

/// Entity types
public enum EntityType: String, Codable, CaseIterable, Sendable {
    case sensor = "sensor"
    case binarySensor = "binary_sensor"
    case `switch` = "switch"
    case light = "light"
    case climate = "climate"
}

/// Entity state union
public enum EntityState: Codable, Sendable {
    case sensor(value: Float, missing: Bool)
    case binarySensor(value: Bool, missing: Bool)
    case `switch`(value: Bool)
    case light(isOn: Bool, brightness: Float?, red: Float?, green: Float?, blue: Float?)
    case unknown
    
    public var displayValue: String {
        switch self {
        case .sensor(let value, let missing):
            return missing ? "N/A" : String(format: "%.1f", value)
        case .binarySensor(let value, let missing):
            return missing ? "N/A" : (value ? "ON" : "OFF")
        case .`switch`(let value):
            return value ? "ON" : "OFF"
        case .light(let isOn, _, _, _, _):
            return isOn ? "ON" : "OFF"
        case .unknown:
            return "Unknown"
        }
    }
}

/// Device statistics
public struct DeviceStats: Codable {
    public let total: Int
    public let online: Int
    public let offline: Int
    
    public init(total: Int, online: Int, offline: Int) {
        self.total = total
        self.online = online
        self.offline = offline
    }
}