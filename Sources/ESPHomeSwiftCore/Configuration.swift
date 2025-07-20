import Foundation
import Yams

/// Core configuration structure representing an ESPHome Swift project
public struct ESPHomeConfiguration: Codable {
    public let esphomeSwift: CoreConfig
    public let esp32: ESP32Config
    public let wifi: WiFiConfig?
    public let api: APIConfig?
    public let ota: [OTAConfig]?
    public let logger: LoggerConfig?
    public let sensor: [SensorConfig]?
    public let `switch`: [SwitchConfig]?
    public let light: [LightConfig]?
    public let binary_sensor: [BinarySensorConfig]?
    public let matter: MatterConfig?
    
    enum CodingKeys: String, CodingKey {
        case esphomeSwift = "esphome_swift"
        case esp32
        case wifi
        case api
        case ota
        case logger
        case sensor
        case `switch`
        case light
        case binary_sensor
        case matter
    }
    
    public init(
        esphomeSwift: CoreConfig,
        esp32: ESP32Config,
        wifi: WiFiConfig? = nil,
        api: APIConfig? = nil,
        ota: [OTAConfig]? = nil,
        logger: LoggerConfig? = nil,
        sensor: [SensorConfig]? = nil,
        `switch`: [SwitchConfig]? = nil,
        light: [LightConfig]? = nil,
        binary_sensor: [BinarySensorConfig]? = nil,
        matter: MatterConfig? = nil
    ) {
        self.esphomeSwift = esphomeSwift
        self.esp32 = esp32
        self.wifi = wifi
        self.api = api
        self.ota = ota
        self.logger = logger
        self.sensor = sensor
        self.`switch` = `switch`
        self.light = light
        self.binary_sensor = binary_sensor
        self.matter = matter
    }
}

/// Core ESPHome Swift configuration
public struct CoreConfig: Codable {
    public let name: String
    public let friendlyName: String?
    public let comment: String?
    public let areaID: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case friendlyName = "friendly_name"
        case comment
        case areaID = "area_id"
    }
    
    public init(name: String, friendlyName: String? = nil, comment: String? = nil, areaID: String? = nil) {
        self.name = name
        self.friendlyName = friendlyName
        self.comment = comment
        self.areaID = areaID
    }
}

/// ESP32 platform configuration
public struct ESP32Config: Codable {
    public let board: String
    public let framework: FrameworkConfig
    public let flashSize: String?
    
    enum CodingKeys: String, CodingKey {
        case board
        case framework
        case flashSize = "flash_size"
    }
    
    public init(board: String, framework: FrameworkConfig, flashSize: String? = nil) {
        self.board = board
        self.framework = framework
        self.flashSize = flashSize
    }
}

/// Framework configuration (ESP-IDF or Arduino)
public struct FrameworkConfig: Codable {
    public let type: FrameworkType
    public let version: String?
    public let sourceDir: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case version
        case sourceDir = "source_dir"
    }
    
    public init(type: FrameworkType, version: String? = nil, sourceDir: String? = nil) {
        self.type = type
        self.version = version
        self.sourceDir = sourceDir
    }
}

/// Supported framework types (Swift Embedded only)
public enum FrameworkType: String, Codable, CaseIterable {
    case swiftEmbedded = "swift-embedded"
}

/// WiFi configuration
public struct WiFiConfig: Codable {
    public let ssid: String
    public let password: String
    public let ap: AccessPointConfig?
    public let manualIP: ManualIPConfig?
    public let useAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case ssid
        case password
        case ap
        case manualIP = "manual_ip"
        case useAddress = "use_address"
    }
    
    public init(
        ssid: String,
        password: String,
        ap: AccessPointConfig? = nil,
        manualIP: ManualIPConfig? = nil,
        useAddress: String? = nil
    ) {
        self.ssid = ssid
        self.password = password
        self.ap = ap
        self.manualIP = manualIP
        self.useAddress = useAddress
    }
}

/// Access point configuration for fallback
public struct AccessPointConfig: Codable {
    public let ssid: String?
    public let password: String?
    
    public init(ssid: String? = nil, password: String? = nil) {
        self.ssid = ssid
        self.password = password
    }
}

/// Manual IP configuration
public struct ManualIPConfig: Codable {
    public let staticIP: String
    public let gateway: String
    public let subnet: String
    public let dns1: String?
    public let dns2: String?
    
    enum CodingKeys: String, CodingKey {
        case staticIP = "static_ip"
        case gateway
        case subnet
        case dns1
        case dns2
    }
    
    public init(staticIP: String, gateway: String, subnet: String, dns1: String? = nil, dns2: String? = nil) {
        self.staticIP = staticIP
        self.gateway = gateway
        self.subnet = subnet
        self.dns1 = dns1
        self.dns2 = dns2
    }
}

/// API configuration
public struct APIConfig: Codable {
    public let encryption: EncryptionConfig?
    public let port: Int?
    public let password: String?
    public let rebootTimeout: String?
    
    enum CodingKeys: String, CodingKey {
        case encryption
        case port
        case password
        case rebootTimeout = "reboot_timeout"
    }
    
    public init(
        encryption: EncryptionConfig? = nil,
        port: Int? = nil,
        password: String? = nil,
        rebootTimeout: String? = nil
    ) {
        self.encryption = encryption
        self.port = port
        self.password = password
        self.rebootTimeout = rebootTimeout
    }
}

/// API encryption configuration
public struct EncryptionConfig: Codable {
    public let key: String
    
    public init(key: String) {
        self.key = key
    }
}

/// OTA (Over-The-Air) update configuration
public struct OTAConfig: Codable {
    public let platform: String
    public let password: String?
    public let id: String?
    
    public init(platform: String, password: String? = nil, id: String? = nil) {
        self.platform = platform
        self.password = password
        self.id = id
    }
}

/// Logger configuration
public struct LoggerConfig: Codable {
    public let level: LogLevel?
    public let baudRate: Int?
    public let txBuffer: Int?
    
    enum CodingKeys: String, CodingKey {
        case level
        case baudRate = "baud_rate"
        case txBuffer = "tx_buffer"
    }
    
    public init(level: LogLevel? = nil, baudRate: Int? = nil, txBuffer: Int? = nil) {
        self.level = level
        self.baudRate = baudRate
        self.txBuffer = txBuffer
    }
}

/// Log levels
public enum LogLevel: String, Codable, CaseIterable {
    case none = "NONE"
    case error = "ERROR"
    case warn = "WARN"
    case info = "INFO"
    case debug = "DEBUG"
    case verbose = "VERBOSE"
    case veryVerbose = "VERY_VERBOSE"
}