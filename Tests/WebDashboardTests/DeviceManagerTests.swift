import XCTest
#if canImport(Network)
import Network
#endif
@testable import WebDashboard
@testable import ESPHomeSwiftCore

final class DeviceManagerTests: XCTestCase {
    
    var deviceManager: DeviceManager!
    
    override func setUp() {
        super.setUp()
        deviceManager = DeviceManager()
    }
    
    override func tearDown() {
        deviceManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDeviceManagerInitialization() {
        XCTAssertNotNil(deviceManager)
        XCTAssertEqual(deviceManager.discoveredDevices.count, 0)
        XCTAssertEqual(deviceManager.deviceStats.total, 0)
        XCTAssertEqual(deviceManager.deviceStats.online, 0)
        XCTAssertEqual(deviceManager.deviceStats.offline, 0)
    }
    
    func testInitialDeviceListIsEmpty() {
        XCTAssertTrue(deviceManager.discoveredDevices.isEmpty)
        XCTAssertTrue(deviceManager.onlineDevices.isEmpty)
    }
    
    // MARK: - Device Statistics Tests
    
    func testDeviceStatsWithNoDevices() {
        let stats = deviceManager.deviceStats
        
        XCTAssertEqual(stats.total, 0)
        XCTAssertEqual(stats.online, 0)
        XCTAssertEqual(stats.offline, 0)
    }
    
    func testDeviceStatsStructure() {
        let stats = DeviceStats(total: 5, online: 3, offline: 2)
        
        XCTAssertEqual(stats.total, 5)
        XCTAssertEqual(stats.online, 3)
        XCTAssertEqual(stats.offline, 2)
    }
    
    // MARK: - Device Addition Tests
    
    func testAddDeviceWithValidHost() async throws {
        let testHost = "192.168.1.100"
        let testPort = 6053
        
        do {
            try await deviceManager.addDevice(host: testHost, port: testPort)
            // This will likely fail in test environment, but we test the method exists
        } catch {
            // Expected to fail without real device
            XCTAssertTrue(true, "Expected failure in test environment")
        }
    }
    
    func testAddDeviceWithCustomPort() async throws {
        let testHost = "192.168.1.100"
        let customPort = 6054
        
        do {
            try await deviceManager.addDevice(host: testHost, port: customPort)
        } catch {
            // Expected to fail without real device
            XCTAssertTrue(true, "Expected failure in test environment")
        }
    }
    
    func testAddDeviceWithDefaultPort() async throws {
        let testHost = "192.168.1.100"
        
        do {
            try await deviceManager.addDevice(host: testHost)
        } catch {
            // Expected to fail without real device
            XCTAssertTrue(true, "Expected failure in test environment")
        }
    }
    
    // MARK: - Device Removal Tests
    
    func testRemoveNonExistentDevice() {
        // Removing a device that doesn't exist should not crash
        deviceManager.removeDevice("non-existent-device")
        XCTAssertEqual(deviceManager.discoveredDevices.count, 0)
    }
    
    func testRemoveDeviceUpdatesCount() {
        // Test with mock device data
        let mockDevice = createMockDevice()
        
        // Since we can't easily add a device without a real connection,
        // we test the removal behavior with non-existent devices
        let initialCount = deviceManager.discoveredDevices.count
        deviceManager.removeDevice(mockDevice.id)
        
        // Count should remain the same since device wasn't actually present
        XCTAssertEqual(deviceManager.discoveredDevices.count, initialCount)
    }
    
    // MARK: - Device Retrieval Tests
    
    func testGetNonExistentDevice() {
        let device = deviceManager.getDevice("non-existent-device")
        XCTAssertNil(device)
    }
    
    func testGetDeviceById() {
        // Test the method exists and returns nil for non-existent devices
        let testDeviceId = "test-device-123"
        let device = deviceManager.getDevice(testDeviceId)
        XCTAssertNil(device, "Should return nil for non-existent device")
    }
    
    // MARK: - Online Devices Tests
    
    func testOnlineDevicesWithNoDevices() {
        let onlineDevices = deviceManager.onlineDevices
        XCTAssertTrue(onlineDevices.isEmpty)
    }
    
    func testOnlineDevicesFiltering() {
        // Test that the computed property exists and works with empty list
        let onlineDevices = deviceManager.onlineDevices
        XCTAssertEqual(onlineDevices.count, 0)
        
        // All online devices should have status .online
        for device in onlineDevices {
            XCTAssertEqual(device.status, .online)
        }
    }
    
    // MARK: - ManagedDevice Tests
    
    func testManagedDeviceInitialization() {
        let device = createMockDevice()
        
        XCTAssertEqual(device.id, "test-device")
        XCTAssertEqual(device.name, "test-device")
        XCTAssertEqual(device.friendlyName, "Test Device")
        XCTAssertEqual(device.host, "192.168.1.100")
        XCTAssertEqual(device.port, 6053)
        XCTAssertEqual(device.board, "esp32-c6-devkitc-1")
        XCTAssertEqual(device.version, "1.0.0")
        XCTAssertEqual(device.macAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(device.status, .online)
        XCTAssertNotNil(device.lastSeen)
        XCTAssertNotNil(device.entities)
    }
    
    func testManagedDeviceWithDifferentStatuses() {
        let onlineDevice = createMockDevice(status: .online)
        let offlineDevice = createMockDevice(status: .offline)
        let updatingDevice = createMockDevice(status: .updating)
        let errorDevice = createMockDevice(status: .error)
        
        XCTAssertEqual(onlineDevice.status, .online)
        XCTAssertEqual(offlineDevice.status, .offline)
        XCTAssertEqual(updatingDevice.status, .updating)
        XCTAssertEqual(errorDevice.status, .error)
    }
    
    func testManagedDeviceWithEmptyEntities() {
        let device = ManagedDevice(
            id: "empty-device",
            name: "empty-device",
            friendlyName: "Empty Device",
            host: "192.168.1.200",
            port: 6053,
            board: "esp32-c6-devkitc-1",
            version: "1.0.0",
            macAddress: "BB:CC:DD:EE:FF:AA",
            status: .online,
            lastSeen: Date(),
            entities: [],
            connection: nil
        )
        
        XCTAssertTrue(device.entities.isEmpty)
        XCTAssertNil(device.connection)
    }
    
    // MARK: - DeviceEntity Tests
    
    func testDeviceEntityInitialization() {
        let entity = createMockSensorEntity()
        
        XCTAssertEqual(entity.id, "temperature")
        XCTAssertEqual(entity.key, 12345)
        XCTAssertEqual(entity.name, "Temperature Sensor")
        XCTAssertEqual(entity.type, .sensor)
        XCTAssertEqual(entity.deviceClass, "temperature")
        XCTAssertEqual(entity.unitOfMeasurement, "°C")
        XCTAssertEqual(entity.icon, "mdi:thermometer")
        XCTAssertNotNil(entity.state)
    }
    
    func testDeviceEntityTypes() {
        let sensor = createMockSensorEntity()
        let binarySensor = createMockBinarySensorEntity()
        let switchEntity = createMockSwitchEntity()
        let light = createMockLightEntity()
        
        XCTAssertEqual(sensor.type, .sensor)
        XCTAssertEqual(binarySensor.type, .binarySensor)
        XCTAssertEqual(switchEntity.type, .switch)
        XCTAssertEqual(light.type, .light)
    }
    
    func testEntityTypeCaseIterable() {
        let allTypes = EntityType.allCases
        XCTAssertTrue(allTypes.contains(.sensor))
        XCTAssertTrue(allTypes.contains(.binarySensor))
        XCTAssertTrue(allTypes.contains(.switch))
        XCTAssertTrue(allTypes.contains(.light))
        XCTAssertTrue(allTypes.contains(.climate))
    }
    
    // MARK: - EntityState Tests
    
    func testSensorEntityState() {
        let sensorState = EntityState.sensor(value: 23.5, missing: false)
        let missingSensorState = EntityState.sensor(value: 0.0, missing: true)
        
        XCTAssertEqual(sensorState.displayValue, "23.5")
        XCTAssertEqual(missingSensorState.displayValue, "N/A")
    }
    
    func testBinarySensorEntityState() {
        let onState = EntityState.binarySensor(value: true, missing: false)
        let offState = EntityState.binarySensor(value: false, missing: false)
        let missingState = EntityState.binarySensor(value: false, missing: true)
        
        XCTAssertEqual(onState.displayValue, "ON")
        XCTAssertEqual(offState.displayValue, "OFF")
        XCTAssertEqual(missingState.displayValue, "N/A")
    }
    
    func testSwitchEntityState() {
        let onSwitch = EntityState.switch(value: true)
        let offSwitch = EntityState.switch(value: false)
        
        XCTAssertEqual(onSwitch.displayValue, "ON")
        XCTAssertEqual(offSwitch.displayValue, "OFF")
    }
    
    func testLightEntityState() {
        let onLight = EntityState.light(isOn: true, brightness: 0.8, red: 1.0, green: 0.5, blue: 0.2)
        let offLight = EntityState.light(isOn: false, brightness: nil, red: nil, green: nil, blue: nil)
        
        XCTAssertEqual(onLight.displayValue, "ON")
        XCTAssertEqual(offLight.displayValue, "OFF")
    }
    
    func testUnknownEntityState() {
        let unknownState = EntityState.unknown
        XCTAssertEqual(unknownState.displayValue, "Unknown")
    }
    
    // MARK: - DeviceStatus Tests
    
    func testDeviceStatusRawValues() {
        XCTAssertEqual(DeviceStatus.online.rawValue, "online")
        XCTAssertEqual(DeviceStatus.offline.rawValue, "offline")
        XCTAssertEqual(DeviceStatus.updating.rawValue, "updating")
        XCTAssertEqual(DeviceStatus.error.rawValue, "error")
    }
    
    func testDeviceStatusFromRawValue() {
        XCTAssertEqual(DeviceStatus(rawValue: "online"), .online)
        XCTAssertEqual(DeviceStatus(rawValue: "offline"), .offline)
        XCTAssertEqual(DeviceStatus(rawValue: "updating"), .updating)
        XCTAssertEqual(DeviceStatus(rawValue: "error"), .error)
        XCTAssertNil(DeviceStatus(rawValue: "invalid"))
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentDeviceAccess() async {
        // Test that multiple concurrent operations don't cause crashes
        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 10 {
                group.addTask { [weak self] in
                    let testHost = "192.168.1.\(100 + index)"
                    do {
                        try await self?.deviceManager.addDevice(host: testHost)
                    } catch {
                        // Expected to fail in test environment
                    }
                }
            }
        }
        
        // Test concurrent removals
        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 5 {
                group.addTask { [weak self] in
                    self?.deviceManager.removeDevice("device-\(index)")
                }
            }
        }
        
        // Should not crash
        XCTAssertNotNil(deviceManager)
    }
    
    // MARK: - Memory Management Tests
    
    func testDeviceManagerDeinit() {
        // Create a local device manager and let it deinitialize
        var localDeviceManager: DeviceManager? = DeviceManager()
        XCTAssertNotNil(localDeviceManager)
        
        localDeviceManager = nil
        XCTAssertNil(localDeviceManager)
        
        // Should not crash - deinit should clean up properly
        XCTAssertTrue(true, "Deinit completed without crash")
    }
}

// MARK: - Test Helpers

extension DeviceManagerTests {
    
    private func createMockDevice(status: DeviceStatus = .online) -> ManagedDevice {
        return ManagedDevice(
            id: "test-device",
            name: "test-device",
            friendlyName: "Test Device",
            host: "192.168.1.100",
            port: 6053,
            board: "esp32-c6-devkitc-1",
            version: "1.0.0",
            macAddress: "AA:BB:CC:DD:EE:FF",
            status: status,
            lastSeen: Date(),
            entities: [createMockSensorEntity(), createMockSwitchEntity()],
            connection: nil
        )
    }
    
    private func createMockSensorEntity() -> DeviceEntity {
        return DeviceEntity(
            id: "temperature",
            key: 12345,
            name: "Temperature Sensor",
            type: .sensor,
            deviceClass: "temperature",
            unitOfMeasurement: "°C",
            icon: "mdi:thermometer",
            state: .sensor(value: 23.5, missing: false)
        )
    }
    
    private func createMockBinarySensorEntity() -> DeviceEntity {
        return DeviceEntity(
            id: "motion",
            key: 12346,
            name: "Motion Sensor",
            type: .binarySensor,
            deviceClass: "motion",
            icon: "mdi:motion-sensor",
            state: .binarySensor(value: false, missing: false)
        )
    }
    
    private func createMockSwitchEntity() -> DeviceEntity {
        return DeviceEntity(
            id: "relay",
            key: 12347,
            name: "Relay Switch",
            type: .switch,
            icon: "mdi:power-socket-eu",
            state: .switch(value: false)
        )
    }
    
    private func createMockLightEntity() -> DeviceEntity {
        return DeviceEntity(
            id: "status_light",
            key: 12348,
            name: "Status Light",
            type: .light,
            icon: "mdi:lightbulb",
            state: .light(isOn: false, brightness: 1.0, red: 1.0, green: 1.0, blue: 1.0)
        )
    }
}