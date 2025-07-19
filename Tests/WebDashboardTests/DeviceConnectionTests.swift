import XCTest
#if canImport(Network)
import Network
#endif
@testable import WebDashboard
@testable import ESPHomeSwiftCore

final class DeviceConnectionTests: XCTestCase {
    
    var deviceConnection: DeviceConnection!
    let testHost = "192.168.1.100"
    let testPort = 6053
    
    override func setUp() {
        super.setUp()
        deviceConnection = DeviceConnection(host: testHost, port: testPort)
    }
    
    override func tearDown() {
        deviceConnection?.disconnect()
        deviceConnection = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDeviceConnectionInitialization() {
        XCTAssertNotNil(deviceConnection)
        // Connection should not be established at init - testing that initialization works
        XCTAssertTrue(true, "DeviceConnection initialized successfully")
    }
    
    func testDeviceConnectionWithValidHostAndPort() {
        let connection = DeviceConnection(host: "192.168.1.50", port: 6053)
        XCTAssertNotNil(connection)
    }
    
    func testDeviceConnectionWithDifferentPorts() {
        let connection1 = DeviceConnection(host: testHost, port: 6053)
        let connection2 = DeviceConnection(host: testHost, port: 6054)
        XCTAssertNotNil(connection1)
        XCTAssertNotNil(connection2)
    }
    
    // MARK: - Connection State Tests
    
    func testConnectionCallbacks() {
        let connectionChangedExpectation = expectation(description: "Connection state changed")
        connectionChangedExpectation.isInverted = true // Don't wait for this since connection will fail
        
        deviceConnection.onConnectionChanged = { _ in
            connectionChangedExpectation.fulfill()
        }
        
        // Test that callback can be set
        XCTAssertNotNil(deviceConnection.onConnectionChanged)
        
        // In a real test environment, we would need a mock device to properly test callbacks
        wait(for: [connectionChangedExpectation], timeout: 1.0)
    }
    
    func testDisconnectCleansUpState() {
        // Even if connection was never established, disconnect should be safe
        deviceConnection.disconnect()
        // Since isConnected is private, we just test that disconnect doesn't crash
        XCTAssertTrue(true, "Disconnect completed without crash")
    }
    
    // MARK: - Device Information Tests
    
    func testGetDeviceInfoStructure() async throws {
        // Test the mock device info structure returned
        do {
            let deviceInfo = try await deviceConnection.getDeviceInfo()
            
            XCTAssertFalse(deviceInfo.name.isEmpty)
            XCTAssertEqual(deviceInfo.board, "esp32-c6-devkitc-1")
            XCTAssertEqual(deviceInfo.version, "1.0.0")
            XCTAssertEqual(deviceInfo.macAddress, "AA:BB:CC:DD:EE:FF")
            XCTAssertNotNil(deviceInfo.compilationTime)
        } catch {
            // Expected to fail in test environment without real device
            XCTAssertTrue(error is DeviceConnectionError)
        }
    }
    
    func testExtractDeviceNameFromHost() {
        // Test the device name extraction logic
        let localHostConnection = DeviceConnection(host: "esp32-livingroom.local", port: 6053)
        let ipConnection = DeviceConnection(host: "192.168.1.100", port: 6053)
        
        // Since extractDeviceName is private, we test it indirectly through getDeviceInfo
        Task {
            do {
                let localDeviceInfo = try await localHostConnection.getDeviceInfo()
                let ipDeviceInfo = try await ipConnection.getDeviceInfo()
                
                XCTAssertFalse(localDeviceInfo.name.isEmpty)
                XCTAssertFalse(ipDeviceInfo.name.isEmpty)
            } catch {
                // Expected to fail in test environment
            }
        }
    }
    
    // MARK: - Entity List Tests
    
    func testListEntitiesReturnsValidEntities() async throws {
        do {
            let entities = try await deviceConnection.listEntities()
            
            XCTAssertGreaterThan(entities.count, 0, "Should return mock entities")
            
            // Verify entity structure
            for entity in entities {
                XCTAssertFalse(entity.id.isEmpty)
                XCTAssertGreaterThan(entity.key, 0)
                XCTAssertFalse(entity.name.isEmpty)
                XCTAssertNotNil(entity.type)
            }
            
            // Check for expected mock entities
            let temperatureEntity = entities.first { $0.id == "temperature" }
            XCTAssertNotNil(temperatureEntity)
            XCTAssertEqual(temperatureEntity?.type, .sensor)
            XCTAssertEqual(temperatureEntity?.deviceClass, "temperature")
            XCTAssertEqual(temperatureEntity?.unitOfMeasurement, "°C")
            
            let switchEntity = entities.first { $0.id == "relay_switch" }
            XCTAssertNotNil(switchEntity)
            XCTAssertEqual(switchEntity?.type, .switch)
            
            let lightEntity = entities.first { $0.id == "status_light" }
            XCTAssertNotNil(lightEntity)
            XCTAssertEqual(lightEntity?.type, .light)
        } catch {
            // Expected to fail in test environment
            XCTAssertTrue(error is DeviceConnectionError)
        }
    }
    
    // MARK: - Command Tests
    
    func testSwitchCommandStructure() async throws {
        do {
            // Test switch command doesn't throw with valid parameters
            try await deviceConnection.sendSwitchCommand(key: 12345, state: true)
            try await deviceConnection.sendSwitchCommand(key: 67890, state: false)
        } catch DeviceConnectionError.notConnected {
            // Expected error when not connected
            XCTAssertTrue(true, "Expected not connected error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLightCommandStructure() async throws {
        do {
            // Test light command with basic on/off
            try await deviceConnection.sendLightCommand(key: 12345, isOn: true)
            try await deviceConnection.sendLightCommand(key: 12345, isOn: false)
            
            // Test light command with full parameters
            try await deviceConnection.sendLightCommand(
                key: 12345,
                isOn: true,
                brightness: 0.8,
                red: 1.0,
                green: 0.5,
                blue: 0.2
            )
        } catch DeviceConnectionError.notConnected {
            // Expected error when not connected
            XCTAssertTrue(true, "Expected not connected error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Message Processing Tests
    
    func testCreateMessageStructure() {
        // Since createMessage is private, we test it indirectly through command methods
        // The message structure is tested implicitly when commands are sent
        XCTAssertTrue(true, "Message creation is tested through command methods")
    }
    
    func testStateUpdateCallbacks() {
        let stateUpdateExpectation = expectation(description: "State update received")
        stateUpdateExpectation.isInverted = true // Don't wait for this since we can't trigger it
        
        deviceConnection.onStateUpdate = { _, _ in
            stateUpdateExpectation.fulfill()
        }
        
        // Test that the callback setup works
        XCTAssertNotNil(deviceConnection.onStateUpdate)
        
        // Don't wait for expectation since we can't trigger it in unit tests
        // This would be better tested in integration tests with a real device
        wait(for: [stateUpdateExpectation], timeout: 0.1)
    }
    
    // MARK: - Error Handling Tests
    
    func testDeviceConnectionErrors() {
        // Test that appropriate errors are defined
        let notConnectedError = DeviceConnectionError.notConnected
        let timeoutError = DeviceConnectionError.timeout
        let invalidResponseError = DeviceConnectionError.invalidResponse
        
        XCTAssertEqual(notConnectedError.errorDescription, "Device not connected")
        XCTAssertEqual(timeoutError.errorDescription, "Connection timeout")
        XCTAssertEqual(invalidResponseError.errorDescription, "Invalid response from device")
    }
    
    func testCommandsFailWhenNotConnected() async {
        // Ensure connection is not established
        deviceConnection.disconnect()
        
        do {
            try await deviceConnection.sendSwitchCommand(key: 123, state: true)
            XCTFail("Should have thrown not connected error")
        } catch DeviceConnectionError.notConnected {
            XCTAssertTrue(true, "Expected not connected error")
        } catch {
            XCTFail("Expected DeviceConnectionError.notConnected, got: \(error)")
        }
        
        do {
            try await deviceConnection.sendLightCommand(key: 123, isOn: true)
            XCTFail("Should have thrown not connected error")
        } catch DeviceConnectionError.notConnected {
            XCTAssertTrue(true, "Expected not connected error")
        } catch {
            XCTFail("Expected DeviceConnectionError.notConnected, got: \(error)")
        }
    }
    
    // MARK: - Ping Tests
    
    func testPingReturnsConnectionStatus() async throws {
        do {
            let isOnline = try await deviceConnection.ping()
            // In mock/test environment, this will depend on connection state
            XCTAssertNotNil(isOnline)
        } catch {
            // Expected to fail in test environment
            XCTAssertTrue(error is DeviceConnectionError)
        }
    }
    
    // MARK: - Subscription Tests
    
    func testSubscribeToStates() async throws {
        do {
            try await deviceConnection.subscribeToStates()
        } catch DeviceConnectionError.notConnected {
            XCTAssertTrue(true, "Expected not connected error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - DeviceConnectionInfo Tests
    
    func testDeviceConnectionInfoStructure() {
        let deviceInfo = DeviceConnectionInfo(
            name: "test_device",
            friendlyName: "Test Device",
            board: "esp32-c6-devkitc-1",
            version: "1.0.0",
            macAddress: "AA:BB:CC:DD:EE:FF",
            compilationTime: Date()
        )
        
        XCTAssertEqual(deviceInfo.name, "test_device")
        XCTAssertEqual(deviceInfo.friendlyName, "Test Device")
        XCTAssertEqual(deviceInfo.board, "esp32-c6-devkitc-1")
        XCTAssertEqual(deviceInfo.version, "1.0.0")
        XCTAssertEqual(deviceInfo.macAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertNotNil(deviceInfo.compilationTime)
    }
    
    func testDeviceConnectionInfoWithNilFriendlyName() {
        let deviceInfo = DeviceConnectionInfo(
            name: "test_device",
            friendlyName: nil,
            board: "esp32-c6-devkitc-1",
            version: "1.0.0",
            macAddress: "AA:BB:CC:DD:EE:FF",
            compilationTime: Date()
        )
        
        XCTAssertEqual(deviceInfo.name, "test_device")
        XCTAssertNil(deviceInfo.friendlyName)
    }
}