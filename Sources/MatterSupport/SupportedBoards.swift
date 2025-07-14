import Foundation

/// Simple centralized registry for ESP32 board definitions and capabilities
/// Focused specifically on Matter protocol support requirements
public enum SupportedBoards {
    
    // MARK: - Board Collections
    
    /// ESP32-C6 boards that support Matter and Thread
    public static let esp32C6Boards: Set<String> = [
        "esp32-c6-devkitc-1",
        "esp32-c6-devkitm-1"
    ]
    
    /// ESP32-H2 boards that support Matter and Thread (Thread-only, no WiFi)
    public static let esp32H2Boards: Set<String> = [
        "esp32-h2-devkitc-1", 
        "esp32-h2-devkitm-1"
    ]
    
    /// All boards that support Matter protocol
    public static var matterCapableBoards: Set<String> {
        return esp32C6Boards.union(esp32H2Boards)
    }
    
    /// All boards that support Thread networking
    public static var threadCapableBoards: Set<String> {
        return esp32C6Boards.union(esp32H2Boards)
    }
    
    // MARK: - Capability Queries
    
    /// Check if a board supports Matter protocol
    /// - Parameter board: ESP32 board identifier
    /// - Returns: True if the board supports Matter
    public static func supportsMatter(_ board: String) -> Bool {
        return matterCapableBoards.contains(board)
    }
    
    /// Check if a board supports Thread networking
    /// - Parameter board: ESP32 board identifier 
    /// - Returns: True if the board supports Thread
    public static func supportsThread(_ board: String) -> Bool {
        return threadCapableBoards.contains(board)
    }
    
    /// Get a user-friendly description of Matter requirements
    /// - Returns: String describing which boards support Matter
    public static func matterRequirementsDescription() -> String {
        let boardList = matterCapableBoards.sorted().joined(separator: ", ")
        return "Matter requires ESP32-C6 or ESP32-H2 boards. Supported: \(boardList)"
    }
    
    /// Get a user-friendly description of Thread requirements
    /// - Returns: String describing which boards support Thread
    public static func threadRequirementsDescription() -> String {
        let boardList = threadCapableBoards.sorted().joined(separator: ", ")
        return "Thread networking requires ESP32-C6 or ESP32-H2 boards. Supported: \(boardList)"
    }
}