import Foundation

/// Centralized board definitions and capability management for ESP32 variants
public struct BoardCapabilities {
    
    /// ESP32 board definition with hardware capabilities
    public struct BoardDefinition {
        public let identifier: String
        public let displayName: String
        public let chipFamily: ChipFamily
        public let architecture: Architecture
        public let capabilities: Set<BoardCapability>
        public let pinConstraints: any BoardConstraints
        
        public init(
            identifier: String,
            displayName: String,
            chipFamily: ChipFamily,
            architecture: Architecture,
            capabilities: Set<BoardCapability>,
            pinConstraints: any BoardConstraints
        ) {
            self.identifier = identifier
            self.displayName = displayName
            self.chipFamily = chipFamily
            self.architecture = architecture
            self.capabilities = capabilities
            self.pinConstraints = pinConstraints
        }
    }
    
    /// ESP32 chip families
    public enum ChipFamily: String, CaseIterable {
        case esp32c3 = "ESP32-C3"
        case esp32c6 = "ESP32-C6"
        case esp32h2 = "ESP32-H2"
        case esp32p4 = "ESP32-P4"
    }
    
    /// Processor architectures
    public enum Architecture: String {
        case riscv = "RISC-V"
    }
    
    /// Board hardware capabilities
    public enum BoardCapability: String, CaseIterable {
        case wifi = "WiFi"
        case bluetooth = "Bluetooth"
        case thread = "Thread"
        case matter = "Matter"
        case zigbee = "Zigbee"
        case adc = "ADC"
        case pwm = "PWM"
        case i2c = "I2C"
        case spi = "SPI"
        case uart = "UART"
    }
    
    /// All supported board definitions
    public static let supportedBoards: [String: BoardDefinition] = [
        // ESP32-C3 boards
        "esp32-c3-devkitm-1": BoardDefinition(
            identifier: "esp32-c3-devkitm-1",
            displayName: "ESP32-C3 DevKit-M",
            chipFamily: .esp32c3,
            architecture: .riscv,
            capabilities: [.wifi, .bluetooth, .adc, .pwm, .i2c, .spi, .uart],
            pinConstraints: ESP32C3Constraints()
        ),
        
        "esp32-c3-devkitc-02": BoardDefinition(
            identifier: "esp32-c3-devkitc-02",
            displayName: "ESP32-C3 DevKit-C",
            chipFamily: .esp32c3,
            architecture: .riscv,
            capabilities: [.wifi, .bluetooth, .adc, .pwm, .i2c, .spi, .uart],
            pinConstraints: ESP32C3Constraints()
        ),
        
        // ESP32-C6 boards (Matter/Thread/Zigbee capable)
        "esp32-c6-devkitc-1": BoardDefinition(
            identifier: "esp32-c6-devkitc-1",
            displayName: "ESP32-C6 DevKit-C",
            chipFamily: .esp32c6,
            architecture: .riscv,
            capabilities: [.wifi, .bluetooth, .thread, .matter, .zigbee, .adc, .pwm, .i2c, .spi, .uart],
            pinConstraints: ESP32C6Constraints()
        ),
        
        "esp32-c6-devkitm-1": BoardDefinition(
            identifier: "esp32-c6-devkitm-1",
            displayName: "ESP32-C6 DevKit-M",
            chipFamily: .esp32c6,
            architecture: .riscv,
            capabilities: [.wifi, .bluetooth, .thread, .matter, .zigbee, .adc, .pwm, .i2c, .spi, .uart],
            pinConstraints: ESP32C6Constraints()
        ),
        
        // ESP32-H2 boards (Thread-only, no WiFi)
        "esp32-h2-devkitc-1": BoardDefinition(
            identifier: "esp32-h2-devkitc-1",
            displayName: "ESP32-H2 DevKit-C",
            chipFamily: .esp32h2,
            architecture: .riscv,
            capabilities: [.bluetooth, .thread, .matter, .zigbee, .adc, .pwm, .i2c, .spi, .uart],
            pinConstraints: ESP32H2Constraints()
        ),
        
        "esp32-h2-devkitm-1": BoardDefinition(
            identifier: "esp32-h2-devkitm-1",
            displayName: "ESP32-H2 DevKit-M",
            chipFamily: .esp32h2,
            architecture: .riscv,
            capabilities: [.bluetooth, .thread, .matter, .zigbee, .adc, .pwm, .i2c, .spi, .uart],
            pinConstraints: ESP32H2Constraints()
        ),
        
        // ESP32-P4 board (high performance)
        "esp32-p4-function-ev-board": BoardDefinition(
            identifier: "esp32-p4-function-ev-board",
            displayName: "ESP32-P4 Function EV Board",
            chipFamily: .esp32p4,
            architecture: .riscv,
            capabilities: [.adc, .pwm, .i2c, .spi, .uart], // No wireless
            pinConstraints: ESP32P4Constraints()
        )
    ]
    
    /// Check if a board supports a specific capability
    public static func boardSupports(_ board: String, capability: BoardCapability) -> Bool {
        guard let boardDef = supportedBoards[board.lowercased()] else { return false }
        return boardDef.capabilities.contains(capability)
    }
    
    /// Get all boards that support a specific capability
    public static func boardsWithCapability(_ capability: BoardCapability) -> [String] {
        return supportedBoards.compactMap { identifier, board in
            board.capabilities.contains(capability) ? identifier : nil
        }.sorted()
    }
    
    /// Get board definition by identifier
    public static func boardDefinition(for identifier: String) -> BoardDefinition? {
        return supportedBoards[identifier.lowercased()]
    }
    
    /// Get all supported board identifiers
    public static var allSupportedBoards: [String] {
        return Array(supportedBoards.keys).sorted()
    }
    
    /// Get boards by chip family
    public static func boards(for chipFamily: ChipFamily) -> [String] {
        return supportedBoards.compactMap { identifier, board in
            board.chipFamily == chipFamily ? identifier : nil
        }.sorted()
    }
}

// MARK: - Matter-specific extensions

public extension BoardCapabilities {
    
    /// Get all Matter-capable boards
    static var matterCapableBoards: [String] {
        return boardsWithCapability(.matter)
    }
    
    /// Get all Thread-capable boards  
    static var threadCapableBoards: [String] {
        return boardsWithCapability(.thread)
    }
    
    /// Check if board supports Matter protocol
    static func supportsMatter(_ board: String) -> Bool {
        return boardSupports(board, capability: .matter)
    }
    
    /// Check if board supports Thread networking
    static func supportsThread(_ board: String) -> Bool {
        return boardSupports(board, capability: .thread)
    }
    
    /// Generate consistent requirements description for error messages
    /// - Parameter capability: The required capability
    /// - Returns: Formatted string listing all boards supporting the capability
    static func requirementsDescription(for capability: BoardCapability) -> String {
        let supportedBoards = boardsWithCapability(capability)
        return supportedBoards.joined(separator: ", ")
    }
}