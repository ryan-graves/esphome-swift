import Foundation
import ComponentLibrary

/// Matter device types as defined in the Matter specification
public enum MatterDeviceType: String, Codable, CaseIterable {
    // Lighting devices
    case onOffLight = "on_off_light"
    case dimmableLight = "dimmable_light" 
    case colorTemperatureLight = "color_temperature_light"
    case extendedColorLight = "extended_color_light"
    
    // Switch devices
    case onOffSwitch = "on_off_switch"
    case dimmerSwitch = "dimmer_switch"
    case colorDimmerSwitch = "color_dimmer_switch"
    case genericSwitch = "generic_switch"
    
    // Sensor devices
    case temperatureSensor = "temperature_sensor"
    case humiditySensor = "humidity_sensor"
    case occupancySensor = "occupancy_sensor"
    case contactSensor = "contact_sensor"
    case airQualitySensor = "air_quality_sensor"
    case pressureSensor = "pressure_sensor"
    case flowSensor = "flow_sensor"
    case lightSensor = "light_sensor"
    
    // Appliance devices
    case smartPlug = "smart_plug"
    case smartOutlet = "smart_outlet"
    case doorLock = "door_lock"
    case thermostat = "thermostat"
    case fan = "fan"
    case airPurifier = "air_purifier"
    case windowCovering = "window_covering"
    
    // Multi-function devices
    case bridgedNode = "bridged_node"
    case rootNode = "root_node"
    
    /// Get the Matter device type ID as defined in the Matter specification
    public var deviceTypeId: UInt32 {
        switch self {
        // Lighting (0x0100-0x01FF)
        case .onOffLight: return 0x0100
        case .dimmableLight: return 0x0101
        case .colorTemperatureLight: return 0x010C
        case .extendedColorLight: return 0x010D
        // Switches (0x000F-0x0105)  
        case .onOffSwitch: return 0x0103
        case .dimmerSwitch: return 0x0104
        case .colorDimmerSwitch: return 0x0105
        case .genericSwitch: return 0x000F
        // Sensors (0x0015-0x007F)
        case .temperatureSensor: return 0x0302
        case .humiditySensor: return 0x0307
        case .occupancySensor: return 0x0107
        case .contactSensor: return 0x0015
        case .airQualitySensor: return 0x002C
        case .pressureSensor: return 0x0305
        case .flowSensor: return 0x0306
        case .lightSensor: return 0x0106
        // Appliances (0x0200-0x02FF)
        case .smartPlug: return 0x010A
        case .smartOutlet: return 0x010A // Same as smart plug
        case .doorLock: return 0x000A
        case .thermostat: return 0x0301
        case .fan: return 0x002B
        case .airPurifier: return 0x002D
        case .windowCovering: return 0x0202
        // Infrastructure
        case .bridgedNode: return 0x0013
        case .rootNode: return 0x0016
        }
    }
    
    /// Get the required Matter clusters for this device type
    public var requiredClusters: [MatterCluster] {
        switch self {
        case .onOffLight:
            return [.identify, .groups, .scenes, .onOff]
        case .dimmableLight:
            return [.identify, .groups, .scenes, .onOff, .levelControl]
        case .colorTemperatureLight:
            return [.identify, .groups, .scenes, .onOff, .levelControl, .colorControl]
        case .extendedColorLight:
            return [.identify, .groups, .scenes, .onOff, .levelControl, .colorControl]
        case .onOffSwitch:
            return [.identify, .switch]
        case .dimmerSwitch:
            return [.identify, .switch, .levelControl]
        case .colorDimmerSwitch:
            return [.identify, .switch, .levelControl, .colorControl]
        case .genericSwitch:
            return [.identify, .switch]
        case .temperatureSensor:
            return [.identify, .temperatureMeasurement]
        case .humiditySensor:
            return [.identify, .relativeHumidityMeasurement]
        case .occupancySensor:
            return [.identify, .occupancySensing]
        case .contactSensor:
            return [.identify, .booleanState]
        case .airQualitySensor:
            return [.identify, .airQuality]
        case .pressureSensor:
            return [.identify, .pressureMeasurement]
        case .flowSensor:
            return [.identify, .flowMeasurement]
        case .lightSensor:
            return [.identify, .illuminanceMeasurement]
        case .smartPlug, .smartOutlet:
            return [.identify, .groups, .scenes, .onOff]
        case .doorLock:
            return [.identify, .doorLock]
        case .thermostat:
            return [.identify, .thermostat]
        case .fan:
            return [.identify, .fanControl]
        case .airPurifier:
            return [.identify, .fanControl, .airQuality]
        case .windowCovering:
            return [.identify, .windowCovering]
        case .bridgedNode, .rootNode:
            return [.identify, .descriptor]
        }
    }
    
    /// Check if this device type is compatible with the given ESPHome Swift component type
    public func isCompatible(with componentType: ComponentType) -> Bool {
        switch (self, componentType) {
        case (.onOffLight, .light),
             (.dimmableLight, .light),
             (.colorTemperatureLight, .light),
             (.extendedColorLight, .light):
            return true
            
        case (.onOffSwitch, .`switch`),
             (.dimmerSwitch, .`switch`),
             (.colorDimmerSwitch, .`switch`),
             (.genericSwitch, .`switch`):
            return true
            
        case (.temperatureSensor, .sensor),
             (.humiditySensor, .sensor),
             (.pressureSensor, .sensor),
             (.flowSensor, .sensor),
             (.lightSensor, .sensor),
             (.airQualitySensor, .sensor):
            return true
            
        case (.occupancySensor, .binarySensor),
             (.contactSensor, .binarySensor):
            return true
            
        default:
            return false
        }
    }
}

/// Matter clusters as defined in the Matter specification
public enum MatterCluster: String, Codable, CaseIterable {
    // General clusters
    case identify = "identify"
    case groups = "groups"
    case scenes = "scenes"
    case descriptor = "descriptor"
    
    // Lighting clusters
    case onOff = "on_off"
    case levelControl = "level_control"
    case colorControl = "color_control"
    
    // Switch clusters
    case `switch` = "switch"
    
    // Sensor clusters
    case temperatureMeasurement = "temperature_measurement"
    case relativeHumidityMeasurement = "relative_humidity_measurement"
    case pressureMeasurement = "pressure_measurement"
    case flowMeasurement = "flow_measurement"
    case illuminanceMeasurement = "illuminance_measurement"
    case occupancySensing = "occupancy_sensing"
    case booleanState = "boolean_state"
    case airQuality = "air_quality"
    
    // Appliance clusters
    case doorLock = "door_lock"
    case thermostat = "thermostat"
    case fanControl = "fan_control"
    case windowCovering = "window_covering"
    
    /// Get the Matter cluster ID as defined in the specification
    public var clusterId: UInt32 {
        switch self {
        case .identify: return 0x0003
        case .groups: return 0x0004
        case .scenes: return 0x0005
        case .descriptor: return 0x001D
        case .onOff: return 0x0006
        case .levelControl: return 0x0008
        case .colorControl: return 0x0300
        case .switch: return 0x003B
        case .temperatureMeasurement: return 0x0402
        case .relativeHumidityMeasurement: return 0x0405
        case .pressureMeasurement: return 0x0403
        case .flowMeasurement: return 0x0404
        case .illuminanceMeasurement: return 0x0400
        case .occupancySensing: return 0x0406
        case .booleanState: return 0x0045
        case .airQuality: return 0x005B
        case .doorLock: return 0x0101
        case .thermostat: return 0x0201
        case .fanControl: return 0x0202
        case .windowCovering: return 0x0102
        }
    }
}

/// Matter endpoint configuration for multi-endpoint devices
public struct MatterEndpoint: Codable {
    /// Endpoint ID (1-65534, 0 reserved for root endpoint)
    public let endpointId: UInt16
    
    /// Device type for this endpoint
    public let deviceType: MatterDeviceType
    
    /// Associated ESPHome Swift component ID
    public let componentId: String?
    
    /// Custom endpoint label
    public let label: String?
    
    enum CodingKeys: String, CodingKey {
        case endpointId = "endpoint_id"
        case deviceType = "device_type"
        case componentId = "component_id"
        case label
    }
    
    public init(
        endpointId: UInt16,
        deviceType: MatterDeviceType,
        componentId: String? = nil,
        label: String? = nil
    ) {
        self.endpointId = endpointId
        self.deviceType = deviceType
        self.componentId = componentId
        self.label = label
    }
}