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
        guard let boardDef = boardDefinition(for: board) else { return false }
        return boardDef.capabilities.contains(capability)
    }
    
    /// Get all boards that support a specific capability
    public static func boardsWithCapability(_ capability: BoardCapability) -> [String] {
        return supportedBoards.compactMap { identifier, board in
            board.capabilities.contains(capability) ? identifier : nil
        }.sorted()
    }
    
    /// Get board definition by identifier
    /// Supports both exact board names and shorthand aliases (e.g., "esp32c6" for chip families)
    public static func boardDefinition(for identifier: String) -> BoardDefinition? {
        let normalizedId = identifier.lowercased()
        
        // First try exact match
        if let board = supportedBoards[normalizedId] {
            return board
        }
        
        // Try shorthand/alias matching
        switch normalizedId {
        // ESP32-C3 aliases
        case "esp32c3", "esp32-c3":
            return supportedBoards["esp32-c3-devkitm-1"] // Default C3 board
            
        // ESP32-C6 aliases  
        case "esp32c6", "esp32-c6":
            return supportedBoards["esp32-c6-devkitc-1"] // Default C6 board
            
        // ESP32-H2 aliases
        case "esp32h2", "esp32-h2":
            return supportedBoards["esp32-h2-devkitc-1"] // Default H2 board (DevKitC variant)
            
        // ESP32-P4 aliases
        case "esp32p4", "esp32-p4":
            return supportedBoards["esp32-p4-function-ev-board"] // Default P4 board
            
        default:
            return nil
        }
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
    
    /// Map GPIO pin to ADC1 channel for board-specific ADC functionality
    /// - Parameters:
    ///   - pin: GPIO pin number
    ///   - board: Board identifier
    /// - Returns: ADC1 channel number for the pin
    /// - Throws: BoardCapabilityError if pin doesn't support ADC on the board
    static func adcChannelForPin(_ pin: Int, board: String) throws -> Int {
        guard let boardDef = boardDefinition(for: board) else {
            throw BoardCapabilityError.unsupportedBoard(board)
        }
        
        // Board-specific GPIO pin to ADC1 channel mapping
        switch boardDef.chipFamily {
        case .esp32c6:
            // ESP32-C6: GPIO0-7 → ADC1_CHANNEL_0-7
            if pin >= 0 && pin <= 7 {
                return pin
            }
        case .esp32c3:
            // ESP32-C3: GPIO0-4 → ADC1_CHANNEL_0-4
            if pin >= 0 && pin <= 4 {
                return pin
            }
        case .esp32h2:
            // ESP32-H2: GPIO0-4 → ADC1_CHANNEL_0-4
            if pin >= 0 && pin <= 4 {
                return pin
            }
        case .esp32p4:
            // ESP32-P4: GPIO0-7 → ADC1_CHANNEL_0-7
            if pin >= 0 && pin <= 7 {
                return pin
            }
        }
        
        throw BoardCapabilityError.pinNotSupportedForADC(pin, boardDef.chipFamily)
    }
}

/// Errors that can occur during board capability operations
public enum BoardCapabilityError: Error, LocalizedError {
    case unsupportedBoard(String)
    case pinNotSupportedForADC(Int, BoardCapabilities.ChipFamily)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedBoard(let board):
            return "Unsupported board: \(board). Use 'swift run esphome-swift boards' to see available boards."
        case .pinNotSupportedForADC(let pin, let chipFamily):
            return "GPIO\(pin) does not support ADC on \(chipFamily) boards"
        }
    }
}