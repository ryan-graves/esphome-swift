import Foundation
import Network
import Logging
import ESPHomeSwiftCore

/// Device connection for communicating with ESPHome Swift devices via native API
public class DeviceConnection {
    private let host: String
    private let port: Int
    private let logger = Logger(label: "DeviceConnection")
    
    private var connection: NWConnection?
    private var isConnected = false
    private var messageBuffer = Data()
    
    // State callbacks
    public var onStateUpdate: ((UInt32, EntityState) -> Void)?
    public var onConnectionChanged: ((Bool) -> Void)?
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    deinit {
        disconnect()
    }
    
    /// Connect to the device
    public func connect() async throws {
        guard !isConnected else { return }
        
        logger.info("Connecting to device at \\(host):\\(port)")
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port))
        )
        connection = NWConnection(to: endpoint, using: .tcp)
        
        return try await withCheckedThrowingContinuation { continuation in
            connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isConnected = true
                    self?.onConnectionChanged?(true)
                    self?.logger.info("Connected to \(self?.host ?? "unknown")")
                    continuation.resume()
                    
                case .failed(let error):
                    self?.logger.error("Connection failed: \\(error)")
                    continuation.resume(throwing: error)
                    
                case .cancelled:
                    self?.isConnected = false
                    self?.onConnectionChanged?(false)
                    self?.logger.info("Connection cancelled")
                    
                default:
                    break
                }
            }
            
            connection?.start(queue: .global())
        }
    }
    
    /// Disconnect from the device
    public func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        onConnectionChanged?(false)
        logger.info("Disconnected from \\(host)")
    }
    
    /// Send a ping to check if device is responsive
    public func ping() async throws -> Bool {
        try await ensureConnected()
        
        // Send ping request
        let pingMessage = createMessage(type: 7, data: Data()) // PING_REQUEST = 7
        try await sendMessage(pingMessage)
        
        // Wait for ping response (simplified - in reality we'd wait for response)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second timeout
        
        return isConnected
    }
    
    /// Get device information
    public func getDeviceInfo() async throws -> DeviceConnectionInfo {
        try await ensureConnected()
        
        // Send device info request
        let deviceInfoMessage = createMessage(type: 9, data: Data()) // DEVICE_INFO_REQUEST = 9
        try await sendMessage(deviceInfoMessage)
        
        // For now, return mock data - in a real implementation we'd parse the response
        return DeviceConnectionInfo(
            name: extractDeviceName(),
            friendlyName: nil,
            board: "esp32-c6-devkitc-1",
            version: "1.0.0",
            macAddress: "AA:BB:CC:DD:EE:FF",
            compilationTime: Date()
        )
    }
    
    /// List all entities on the device
    public func listEntities() async throws -> [DeviceEntity] {
        try await ensureConnected()
        
        // Send list entities request
        let listMessage = createMessage(type: 11, data: Data()) // LIST_ENTITIES_REQUEST = 11
        try await sendMessage(listMessage)
        
        // For now, return mock entities - in a real implementation we'd parse the response
        return createMockEntities()
    }
    
    /// Subscribe to state updates
    public func subscribeToStates() async throws {
        try await ensureConnected()
        
        // Send subscribe states request
        let subscribeMessage = createMessage(type: 20, data: Data()) // SUBSCRIBE_STATES_REQUEST = 20
        try await sendMessage(subscribeMessage)
        
        // Start receiving state updates
        startReceivingMessages()
    }
    
    /// Send a command to control a switch
    public func sendSwitchCommand(key: UInt32, state: Bool) async throws {
        try await ensureConnected()
        
        // Create switch command message
        var commandData = Data()
        commandData.append(contentsOf: withUnsafeBytes(of: key.littleEndian) { Data($0) })
        commandData.append(state ? 1 : 0)
        
        let commandMessage = createMessage(type: 33, data: commandData) // SWITCH_COMMAND_REQUEST = 33
        try await sendMessage(commandMessage)
    }
    
    /// Send a command to control a light
    public func sendLightCommand(
        key: UInt32,
        isOn: Bool,
        brightness: Float? = nil,
        red: Float? = nil,
        green: Float? = nil,
        blue: Float? = nil
    ) async throws {
        try await ensureConnected()
        
        // Create light command message
        var commandData = Data()
        commandData.append(contentsOf: withUnsafeBytes(of: key.littleEndian) { Data($0) })
        commandData.append(isOn ? 1 : 0)
        
        if let brightness = brightness {
            commandData.append(contentsOf: withUnsafeBytes(of: brightness) { Data($0) })
        }
        
        if let red = red, let green = green, let blue = blue {
            commandData.append(contentsOf: withUnsafeBytes(of: red) { Data($0) })
            commandData.append(contentsOf: withUnsafeBytes(of: green) { Data($0) })
            commandData.append(contentsOf: withUnsafeBytes(of: blue) { Data($0) })
        }
        
        let commandMessage = createMessage(type: 35, data: commandData) // LIGHT_COMMAND_REQUEST = 35
        try await sendMessage(commandMessage)
    }
    
    // MARK: - Private Methods
    
    private func ensureConnected() async throws {
        if !isConnected {
            try await connect()
        }
    }
    
    private func createMessage(type: UInt8, data: Data) -> Data {
        var message = Data()
        
        // Preamble
        message.append(0x00)
        
        // Message length (simplified - should be varint)
        let length = UInt32(data.count + 1) // +1 for message type
        message.append(contentsOf: withUnsafeBytes(of: length.littleEndian) { Data($0) })
        
        // Message type
        message.append(type)
        
        // Message data
        message.append(data)
        
        return message
    }
    
    private func sendMessage(_ message: Data) async throws {
        guard let connection = connection else {
            throw DeviceConnectionError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: message, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    private func startReceivingMessages() {
        guard let connection = connection else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processReceivedData(data)
            }
            
            if error != nil {
                self?.logger.error("Receive error occurred")
                return
            }
            
            if !isComplete {
                // Continue receiving
                self?.startReceivingMessages()
            }
        }
    }
    
    private func processReceivedData(_ data: Data) {
        messageBuffer.append(data)
        
        // Process complete messages from buffer
        while messageBuffer.count >= 5 { // Minimum message size
            let preamble = messageBuffer[0]
            guard preamble == 0x00 else {
                // Invalid preamble, skip byte
                messageBuffer.removeFirst()
                continue
            }
            
            // Read message length (simplified - should parse varint)
            let lengthData = messageBuffer[1 ..< 5]
            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            
            let totalMessageLength = 5 + Int(length)
            guard messageBuffer.count >= totalMessageLength else {
                // Wait for more data
                break
            }
            
            // Extract message
            let messageData = messageBuffer[5 ..< totalMessageLength]
            processMessage(messageData)
            
            // Remove processed message from buffer
            messageBuffer.removeFirst(totalMessageLength)
        }
    }
    
    private func processMessage(_ data: Data) {
        guard !data.isEmpty else { return }
        
        let messageType = data[0]
        let payload = data.dropFirst()
        
        switch messageType {
        case 22: // BINARY_SENSOR_STATE_RESPONSE
            processBinarySensorState(payload)
        case 25: // SENSOR_STATE_RESPONSE
            processSensorState(payload)
        case 27: // SWITCH_STATE_RESPONSE
            processSwitchState(payload)
        case 29: // LIGHT_STATE_RESPONSE
            processLightState(payload)
        default:
            logger.debug("Unhandled message type: \\(messageType)")
        }
    }
    
    private func processBinarySensorState(_ data: Data) {
        guard data.count >= 5 else { return }
        
        let key = data[0 ..< 4].withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        let state = data[4] != 0
        
        let entityState = EntityState.binarySensor(value: state, missing: false)
        onStateUpdate?(key, entityState)
    }
    
    private func processSensorState(_ data: Data) {
        guard data.count >= 8 else { return }
        
        let key = data[0 ..< 4].withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        let value = data[4 ..< 8].withUnsafeBytes { $0.load(as: Float.self) }
        
        let entityState = EntityState.sensor(value: value, missing: false)
        onStateUpdate?(key, entityState)
    }
    
    private func processSwitchState(_ data: Data) {
        guard data.count >= 5 else { return }
        
        let key = data[0 ..< 4].withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        let state = data[4] != 0
        
        let entityState = EntityState.`switch`(value: state)
        onStateUpdate?(key, entityState)
    }
    
    private func processLightState(_ data: Data) {
        guard data.count >= 5 else { return }
        
        let key = data[0 ..< 4].withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        let isOn = data[4] != 0
        
        // Simplified light state parsing
        let entityState = EntityState.light(isOn: isOn, brightness: nil, red: nil, green: nil, blue: nil)
        onStateUpdate?(key, entityState)
    }
    
    private func extractDeviceName() -> String {
        // Extract device name from host (simplified)
        if host.contains(".local") {
            return String(host.prefix(while: { $0 != "." }))
        }
        let cleanHost = host.replacingOccurrences(of: ".", with: "-")
        return "device-\(cleanHost)"
    }
    
    private func createMockEntities() -> [DeviceEntity] {
        // Create mock entities for demonstration
        return [
            DeviceEntity(
                id: "temperature",
                key: 12345,
                name: "Temperature",
                type: .sensor,
                deviceClass: "temperature",
                unitOfMeasurement: "°C",
                state: .sensor(value: 23.5, missing: false)
            ),
            DeviceEntity(
                id: "humidity",
                key: 12346,
                name: "Humidity",
                type: .sensor,
                deviceClass: "humidity",
                unitOfMeasurement: "%",
                state: .sensor(value: 45.2, missing: false)
            ),
            DeviceEntity(
                id: "relay_switch",
                key: 12347,
                name: "Relay Switch",
                type: .switch,
                icon: "mdi:power-socket-eu",
                state: .`switch`(value: false)
            ),
            DeviceEntity(
                id: "status_light",
                key: 12348,
                name: "Status Light",
                type: .light,
                state: .light(isOn: false, brightness: 1.0, red: 1.0, green: 1.0, blue: 1.0)
            )
        ]
    }
}

/// Device information from API connection
public struct DeviceConnectionInfo {
    public let name: String
    public let friendlyName: String?
    public let board: String
    public let version: String
    public let macAddress: String
    public let compilationTime: Date
    
    public init(
        name: String,
        friendlyName: String?,
        board: String,
        version: String,
        macAddress: String,
        compilationTime: Date
    ) {
        self.name = name
        self.friendlyName = friendlyName
        self.board = board
        self.version = version
        self.macAddress = macAddress
        self.compilationTime = compilationTime
    }
}

/// Device connection errors
public enum DeviceConnectionError: Error, LocalizedError {
    case notConnected
    case connectionFailed(Error)
    case invalidResponse
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Device not connected"
        case .connectionFailed:
            return "Connection failed"
        case .invalidResponse:
            return "Invalid response from device"
        case .timeout:
            return "Connection timeout"
        }
    }
}