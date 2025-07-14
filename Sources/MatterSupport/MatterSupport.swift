import Foundation
import ESPHomeSwiftCore

/// MatterSupport module for ESPHome Swift
/// 
/// This module provides Matter protocol integration for ESP32-C6/H2 devices,
/// enabling participation in the broader smart home ecosystem through the
/// ESP-Matter SDK and Thread/Wi-Fi connectivity.
///
/// Key Features:
/// - Matter device type definitions and validation
/// - ESP-Matter SDK code generation integration  
/// - Thread network configuration for ESP32-C6/H2
/// - Device commissioning and discovery support
public struct MatterSupport {
    
    /// Current Matter support version
    public static let version = "1.0.0"
    
    /// Supported ESP32 boards for Matter functionality
    /// Uses centralized BoardCapabilities for maintainable board management
    public static var supportedBoards: Set<String> {
        return Set(BoardCapabilities.matterCapableBoards)
    }
    
    /// Validates if the given board supports Matter functionality
    /// - Parameter board: ESP32 board identifier
    /// - Returns: True if Matter is supported on this board
    public static func isSupported(board: String) -> Bool {
        return supportedBoards.contains(board)
    }
    
    /// Gets the recommended ESP-IDF version for Matter support
    public static let requiredESPIDFVersion = "v5.4.1"
    
    /// Gets the minimum flash size required for Matter functionality (in MB)
    public static let minimumFlashSize = 4
    
    /// Gets the minimum RAM requirement for Matter functionality (in KB) 
    public static let minimumRAM = 400
}