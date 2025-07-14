import Foundation

// MARK: - Base Component Protocol

/// Base protocol for all ESPHome Swift components
public protocol ComponentConfig: Codable {
    var id: String? { get }
    var name: String? { get }
    var platform: String { get }
}

// MARK: - Sensor Components

/// Base sensor configuration
public struct SensorConfig: ComponentConfig {
    public let platform: String
    public let id: String?
    public let name: String?
    public let pin: PinConfig?
    public let updateInterval: String?
    public let accuracy: Int?
    public let filters: [FilterConfig]?
    
    // DHT-specific properties
    public let model: DHTModel?
    public let temperature: SensorSubConfig?
    public let humidity: SensorSubConfig?
    
    enum CodingKeys: String, CodingKey {
        case platform
        case id
        case name
        case pin
        case updateInterval = "update_interval"
        case accuracy
        case filters
        case model
        case temperature
        case humidity
    }
    
    public init(
        platform: String,
        id: String? = nil,
        name: String? = nil,
        pin: PinConfig? = nil,
        updateInterval: String? = nil,
        accuracy: Int? = nil,
        filters: [FilterConfig]? = nil,
        model: DHTModel? = nil,
        temperature: SensorSubConfig? = nil,
        humidity: SensorSubConfig? = nil
    ) {
        self.platform = platform
        self.id = id
        self.name = name
        self.pin = pin
        self.updateInterval = updateInterval
        self.accuracy = accuracy
        self.filters = filters
        self.model = model
        self.temperature = temperature
        self.humidity = humidity
    }
}

/// DHT sensor models
public enum DHTModel: String, Codable, CaseIterable {
    case dht11 = "DHT11"
    case dht22 = "DHT22"
    case am2302 = "AM2302"
}

/// Sensor sub-configuration (for multi-value sensors like DHT)
public struct SensorSubConfig: Codable {
    public let name: String?
    public let id: String?
    public let filters: [FilterConfig]?
    
    public init(name: String? = nil, id: String? = nil, filters: [FilterConfig]? = nil) {
        self.name = name
        self.id = id
        self.filters = filters
    }
}

/// Sensor filter configuration
public struct FilterConfig: Codable {
    public let type: FilterType
    public let value: FilterValue?
    
    public init(type: FilterType, value: FilterValue? = nil) {
        self.type = type
        self.value = value
    }
}

/// Filter types
public enum FilterType: String, Codable, CaseIterable {
    case offset
    case multiply
    case calibrateLinear = "calibrate_linear"
    case lambda
    case slidingWindowMovingAverage = "sliding_window_moving_average"
    case exponentialMovingAverage = "exponential_moving_average"
}

/// Filter values (can be string, number, or array)
public enum FilterValue: Codable {
    case string(String)
    case double(Double)
    case array([Double])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let arrayValue = try? container.decode([Double].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(
                FilterValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Filter value must be string, number, or array"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Switch Components

/// Switch configuration
public struct SwitchConfig: ComponentConfig {
    public let platform: String
    public let id: String?
    public let name: String?
    public let pin: PinConfig?
    public let inverted: Bool?
    public let restoreMode: RestoreMode?
    
    enum CodingKeys: String, CodingKey {
        case platform
        case id
        case name
        case pin
        case inverted
        case restoreMode = "restore_mode"
    }
    
    public init(
        platform: String,
        id: String? = nil,
        name: String? = nil,
        pin: PinConfig? = nil,
        inverted: Bool? = nil,
        restoreMode: RestoreMode? = nil
    ) {
        self.platform = platform
        self.id = id
        self.name = name
        self.pin = pin
        self.inverted = inverted
        self.restoreMode = restoreMode
    }
}

/// Switch restore modes
public enum RestoreMode: String, Codable, CaseIterable {
    case restoreDefaultOff = "RESTORE_DEFAULT_OFF"
    case restoreDefaultOn = "RESTORE_DEFAULT_ON"
    case alwaysOff = "ALWAYS_OFF"
    case alwaysOn = "ALWAYS_ON"
    case restoreInvertedDefaultOff = "RESTORE_INVERTED_DEFAULT_OFF"
    case restoreInvertedDefaultOn = "RESTORE_INVERTED_DEFAULT_ON"
}

// MARK: - Light Components

/// Light configuration
public struct LightConfig: ComponentConfig {
    public let platform: String
    public let id: String?
    public let name: String?
    public let pin: PinConfig?
    public let redPin: PinConfig?
    public let greenPin: PinConfig?
    public let bluePin: PinConfig?
    public let whitePin: PinConfig?
    public let effects: [LightEffectConfig]?
    
    enum CodingKeys: String, CodingKey {
        case platform
        case id
        case name
        case pin
        case redPin = "red_pin"
        case greenPin = "green_pin"
        case bluePin = "blue_pin"
        case whitePin = "white_pin"
        case effects
    }
    
    public init(
        platform: String,
        id: String? = nil,
        name: String? = nil,
        pin: PinConfig? = nil,
        redPin: PinConfig? = nil,
        greenPin: PinConfig? = nil,
        bluePin: PinConfig? = nil,
        whitePin: PinConfig? = nil,
        effects: [LightEffectConfig]? = nil
    ) {
        self.platform = platform
        self.id = id
        self.name = name
        self.pin = pin
        self.redPin = redPin
        self.greenPin = greenPin
        self.bluePin = bluePin
        self.whitePin = whitePin
        self.effects = effects
    }
}

/// Light effect configuration
public struct LightEffectConfig: Codable {
    public let name: String
    public let type: LightEffectType?
    
    public init(name: String, type: LightEffectType? = nil) {
        self.name = name
        self.type = type
    }
}

/// Light effect types
public enum LightEffectType: String, Codable, CaseIterable {
    case rainbow
    case colorWipe = "color_wipe"
    case scan
    case twinkle
    case randomTwinkle = "random_twinkle"
    case fireworks
    case flicker
    case addressableRainbow = "addressable_rainbow"
    case strobe
    case pulse
    case breathe
}

// MARK: - Binary Sensor Components

/// Binary sensor configuration
public struct BinarySensorConfig: ComponentConfig {
    public let platform: String
    public let id: String?
    public let name: String?
    public let pin: PinConfig?
    public let deviceClass: BinarySensorDeviceClass?
    public let inverted: Bool?
    public let filters: [BinarySensorFilterConfig]?
    
    enum CodingKeys: String, CodingKey {
        case platform
        case id
        case name
        case pin
        case deviceClass = "device_class"
        case inverted
        case filters
    }
    
    public init(
        platform: String,
        id: String? = nil,
        name: String? = nil,
        pin: PinConfig? = nil,
        deviceClass: BinarySensorDeviceClass? = nil,
        inverted: Bool? = nil,
        filters: [BinarySensorFilterConfig]? = nil
    ) {
        self.platform = platform
        self.id = id
        self.name = name
        self.pin = pin
        self.deviceClass = deviceClass
        self.inverted = inverted
        self.filters = filters
    }
}

/// Binary sensor device classes
public enum BinarySensorDeviceClass: String, Codable, CaseIterable {
    case none
    case battery
    case batteryCharging = "battery_charging"
    case co = "carbon_monoxide"
    case cold
    case connectivity
    case door
    case garageDoor = "garage_door"
    case gas
    case heat
    case light
    case lock
    case moisture
    case motion
    case moving
    case occupancy
    case opening
    case plug
    case power
    case presence
    case problem
    case running
    case safety
    case smoke
    case sound
    case tamper
    case update
    case vibration
    case window
}

/// Binary sensor filter configuration
public struct BinarySensorFilterConfig: Codable {
    public let type: BinarySensorFilterType
    public let duration: String?
    
    public init(type: BinarySensorFilterType, duration: String? = nil) {
        self.type = type
        self.duration = duration
    }
}

/// Binary sensor filter types
public enum BinarySensorFilterType: String, Codable, CaseIterable {
    case invert
    case delayedOn = "delayed_on"
    case delayedOff = "delayed_off"
    case delayedOnOff = "delayed_on_off"
}

// MARK: - Pin Configuration

/// Pin configuration
public struct PinConfig: Codable {
    public let number: PinNumber
    public let mode: PinMode?
    public let inverted: Bool?
    
    public init(number: PinNumber, mode: PinMode? = nil, inverted: Bool? = nil) {
        self.number = number
        self.mode = mode
        self.inverted = inverted
    }
}

/// Pin number (can be integer or GPIO string)
public enum PinNumber: Codable {
    case integer(Int)
    case gpio(String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self = .integer(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .gpio(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                PinNumber.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Pin number must be integer or GPIO string"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .integer(let value):
            try container.encode(value)
        case .gpio(let value):
            try container.encode(value)
        }
    }
}

/// Pin modes
public enum PinMode: String, Codable, CaseIterable {
    case input = "INPUT"
    case output = "OUTPUT"
    case inputPullup = "INPUT_PULLUP"
    case inputPulldown = "INPUT_PULLDOWN"
    case outputOpenDrain = "OUTPUT_OPEN_DRAIN"
}