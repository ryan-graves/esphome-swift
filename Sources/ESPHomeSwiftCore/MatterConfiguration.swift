import Foundation

/// Matter protocol configuration for ESPHome Swift devices
/// (Core definitions in ESPHomeSwiftCore to avoid circular dependencies)
public struct MatterConfig: Codable {
    /// Enable or disable Matter support
    public let enabled: Bool
    
    /// Matter device type identifier  
    public let deviceType: String
    
    /// Vendor ID for Matter device identification
    public let vendorId: UInt16
    
    /// Product ID for Matter device identification
    public let productId: UInt16
    
    /// Device commissioning configuration
    public let commissioning: CommissioningConfig?
    
    /// Thread network configuration (for ESP32-C6/H2)
    public let thread: ThreadConfig?
    
    /// Matter-specific network configuration
    public let network: MatterNetworkConfig?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case deviceType = "device_type"
        case vendorId = "vendor_id"
        case productId = "product_id"
        case commissioning
        case thread
        case network
    }
    
    public init(
        enabled: Bool = true,
        deviceType: String,
        vendorId: UInt16 = 0xFFF1,
        productId: UInt16 = 0x8000,
        commissioning: CommissioningConfig? = nil,
        thread: ThreadConfig? = nil,
        network: MatterNetworkConfig? = nil
    ) {
        self.enabled = enabled
        self.deviceType = deviceType
        self.vendorId = vendorId
        self.productId = productId
        self.commissioning = commissioning
        self.thread = thread
        self.network = network
    }
}

/// Matter device commissioning configuration
public struct CommissioningConfig: Codable {
    /// Commissioning discriminator (12-bit value)
    public let discriminator: UInt16
    
    /// Setup passcode for commissioning
    public let passcode: UInt32
    
    /// Manual pairing code (optional)
    public let manualPairingCode: String?
    
    /// QR code payload (optional, generated if not provided)
    public let qrCodePayload: String?
    
    enum CodingKeys: String, CodingKey {
        case discriminator
        case passcode
        case manualPairingCode = "manual_pairing_code"
        case qrCodePayload = "qr_code_payload"
    }
    
    public init(
        discriminator: UInt16 = 3840,
        passcode: UInt32 = 20202021,
        manualPairingCode: String? = nil,
        qrCodePayload: String? = nil
    ) {
        self.discriminator = discriminator
        self.passcode = passcode
        self.manualPairingCode = manualPairingCode
        self.qrCodePayload = qrCodePayload
    }
}

/// Thread network configuration for ESP32-C6/H2
public struct ThreadConfig: Codable {
    /// Enable Thread networking
    public let enabled: Bool
    
    /// Thread network dataset (operational dataset TLV)
    public let dataset: String?
    
    /// Thread network name
    public let networkName: String?
    
    /// Extended PAN ID (16 bytes hex string)
    public let extPanId: String?
    
    /// Thread network key (16 bytes hex string)
    public let networkKey: String?
    
    /// Channel number (11-26)
    public let channel: UInt8?
    
    /// PAN ID (16-bit value)
    public let panId: UInt16?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case dataset
        case networkName = "network_name"
        case extPanId = "ext_pan_id"
        case networkKey = "network_key"
        case channel
        case panId = "pan_id"
    }
    
    public init(
        enabled: Bool = true,
        dataset: String? = nil,
        networkName: String? = nil,
        extPanId: String? = nil,
        networkKey: String? = nil,
        channel: UInt8? = nil,
        panId: UInt16? = nil
    ) {
        self.enabled = enabled
        self.dataset = dataset
        self.networkName = networkName
        self.extPanId = extPanId
        self.networkKey = networkKey
        self.channel = channel
        self.panId = panId
    }
}

/// Matter network configuration options
public struct MatterNetworkConfig: Codable {
    /// Preferred transport protocol
    public let transport: String
    
    /// Enable IPv6 support
    public let ipv6Enabled: Bool
    
    /// Multicast DNS configuration
    public let mdns: MDNSConfig?
    
    enum CodingKeys: String, CodingKey {
        case transport
        case ipv6Enabled = "ipv6_enabled"
        case mdns
    }
    
    public init(
        transport: String = "wifi",
        ipv6Enabled: Bool = true,
        mdns: MDNSConfig? = nil
    ) {
        self.transport = transport
        self.ipv6Enabled = ipv6Enabled
        self.mdns = mdns
    }
}

/// Multicast DNS configuration
public struct MDNSConfig: Codable {
    /// Enable mDNS advertisement
    public let enabled: Bool
    
    /// Custom mDNS hostname
    public let hostname: String?
    
    /// Additional mDNS services to advertise
    public let services: [String]?
    
    public init(
        enabled: Bool = true,
        hostname: String? = nil,
        services: [String]? = nil
    ) {
        self.enabled = enabled
        self.hostname = hostname
        self.services = services
    }
}