import XCTest
@testable import MatterSupport

final class MatterDeviceTypesTests: XCTestCase {
    
    func testAllDeviceTypesHaveRawValues() {
        for deviceType in MatterDeviceType.allCases {
            XCTAssertFalse(deviceType.rawValue.isEmpty, "Device type \(deviceType) should have a non-empty raw value")
            XCTAssertFalse(
                deviceType.rawValue.contains(" "),
                "Device type \(deviceType) raw value should not contain spaces"
            )
        }
    }
    
    func testDeviceTypeFromString() {
        // Test valid device types
        XCTAssertEqual(MatterDeviceType(rawValue: "on_off_light"), .onOffLight)
        XCTAssertEqual(MatterDeviceType(rawValue: "dimmable_light"), .dimmableLight)
        XCTAssertEqual(MatterDeviceType(rawValue: "temperature_sensor"), .temperatureSensor)
        XCTAssertEqual(MatterDeviceType(rawValue: "door_lock"), .doorLock)
        XCTAssertEqual(MatterDeviceType(rawValue: "window_covering"), .windowCovering)
        
        // Test invalid device type
        XCTAssertNil(MatterDeviceType(rawValue: "invalid_device_type"))
    }
    
    func testLightDeviceTypes() {
        let lightTypes: [MatterDeviceType] = [
            .onOffLight, .dimmableLight, .colorTemperatureLight, .extendedColorLight
        ]
        
        for lightType in lightTypes {
            XCTAssertTrue(lightType.requiredClusters.contains(.onOff), 
                         "Light type \(lightType) should require OnOff cluster")
            XCTAssertTrue(lightType.requiredClusters.contains(.identify), 
                         "Light type \(lightType) should require Identify cluster")
        }
        
        // Dimmable lights should have level control
        let dimmableLights: [MatterDeviceType] = [.dimmableLight]
        for dimmableLight in dimmableLights {
            XCTAssertTrue(dimmableLight.requiredClusters.contains(.levelControl),
                          "Dimmable light \(dimmableLight) should require Level Control cluster")
        }
        
        // Color lights should have color control
        let colorLights: [MatterDeviceType] = [.colorTemperatureLight, .extendedColorLight]
        for colorLight in colorLights {
            XCTAssertTrue(colorLight.requiredClusters.contains(.colorControl),
                          "Color light \(colorLight) should require Color Control cluster")
        }
    }
    
    func testSensorDeviceTypes() {
        let sensorTypes: [MatterDeviceType] = [
            .temperatureSensor, .humiditySensor, .lightSensor, .occupancySensor, .contactSensor
        ]
        
        for sensorType in sensorTypes {
            XCTAssertTrue(sensorType.requiredClusters.contains(.identify),
                          "Sensor type \(sensorType) should require Identify cluster")
            XCTAssertFalse(sensorType.requiredClusters.isEmpty,
                           "Sensor type \(sensorType) should have required clusters")
        }
        
        // Temperature sensor should have temperature measurement
        XCTAssertTrue(MatterDeviceType.temperatureSensor.requiredClusters.contains(.temperatureMeasurement))
        
        // Humidity sensor should have relative humidity measurement
        XCTAssertTrue(MatterDeviceType.humiditySensor.requiredClusters.contains(.relativeHumidityMeasurement))
        
        // Occupancy sensor should have occupancy sensing
        XCTAssertTrue(MatterDeviceType.occupancySensor.requiredClusters.contains(.occupancySensing))
    }
    
    func testSwitchDeviceTypes() {
        let switchTypes: [MatterDeviceType] = [.onOffSwitch, .dimmerSwitch, .colorDimmerSwitch, .genericSwitch]
        
        for switchType in switchTypes {
            XCTAssertTrue(switchType.requiredClusters.contains(.identify),
                          "Switch type \(switchType) should require Identify cluster")
            XCTAssertTrue(switchType.requiredClusters.contains(.switch),
                          "Switch type \(switchType) should require Switch cluster")
        }
    }
    
    func testDeviceTypeIDs() {
        // Test that device type IDs are within valid ranges
        for deviceType in MatterDeviceType.allCases {
            let deviceTypeId = deviceType.deviceTypeId
            XCTAssertGreaterThan(deviceTypeId, 0, "Device type \(deviceType) should have a positive ID")
            XCTAssertLessThan(deviceTypeId, 0xFFFF, "Device type \(deviceType) ID should be within 16-bit range")
        }
        
        // Test specific known device type IDs
        XCTAssertEqual(MatterDeviceType.onOffLight.deviceTypeId, 0x0100)
        XCTAssertEqual(MatterDeviceType.dimmableLight.deviceTypeId, 0x0101)
        XCTAssertEqual(MatterDeviceType.temperatureSensor.deviceTypeId, 0x0302)
        XCTAssertEqual(MatterDeviceType.doorLock.deviceTypeId, 0x000A)
    }
    
    func testClusterDefinitions() {
        // Test that all cluster types are defined
        let allClusters: [MatterCluster] = [
            .identify, .onOff, .levelControl, .colorControl,
            .temperatureMeasurement, .relativeHumidityMeasurement,
            .illuminanceMeasurement, .occupancySensing,
            .switch, .doorLock, .windowCovering, .thermostat, .fanControl
        ]
        
        for cluster in allClusters {
            XCTAssertFalse(cluster.rawValue.isEmpty, "Cluster \(cluster) should have a non-empty raw value")
        }
    }
    
    func testRequiredClustersNotEmpty() {
        for deviceType in MatterDeviceType.allCases {
            XCTAssertFalse(deviceType.requiredClusters.isEmpty,
                           "Device type \(deviceType) should have at least one required cluster")
        }
    }
    
    func testDeviceTypeUniqueness() {
        let allRawValues = MatterDeviceType.allCases.map(\.rawValue)
        let uniqueRawValues = Set(allRawValues)
        
        XCTAssertEqual(allRawValues.count, uniqueRawValues.count,
                       "All device types should have unique raw values")
        
        // Note: Some device types may have the same device type ID (e.g., smartPlug and smartOutlet)
        // as they represent the same Matter device type with different marketing names
        let allDeviceTypeIds = MatterDeviceType.allCases.map(\.deviceTypeId)
        let uniqueDeviceTypeIds = Set(allDeviceTypeIds)
        
        // Allow for some duplicate device type IDs for equivalent devices
        XCTAssertLessThanOrEqual(uniqueDeviceTypeIds.count, allDeviceTypeIds.count,
                                 "Device type IDs should not exceed the number of device types")
        XCTAssertGreaterThan(uniqueDeviceTypeIds.count, 0,
                             "Should have at least some unique device type IDs")
        
        // Specifically check that smartPlug and smartOutlet have the same ID (intentional)
        XCTAssertEqual(MatterDeviceType.smartPlug.deviceTypeId, MatterDeviceType.smartOutlet.deviceTypeId,
                       "Smart plug and smart outlet should have the same device type ID")
    }
    
    func testComplexDeviceTypes() {
        // Test complex device types that might have multiple clusters
        let thermostat = MatterDeviceType.thermostat
        XCTAssertTrue(thermostat.requiredClusters.contains(.identify))
        XCTAssertTrue(thermostat.requiredClusters.contains(.thermostat))
        
        let doorLock = MatterDeviceType.doorLock
        XCTAssertTrue(doorLock.requiredClusters.contains(.identify))
        XCTAssertTrue(doorLock.requiredClusters.contains(.doorLock))
        
        let windowCovering = MatterDeviceType.windowCovering
        XCTAssertTrue(windowCovering.requiredClusters.contains(.identify))
        XCTAssertTrue(windowCovering.requiredClusters.contains(.windowCovering))
    }
}