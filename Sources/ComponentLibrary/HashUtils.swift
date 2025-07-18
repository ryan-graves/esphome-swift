import Foundation

/// Shared hash utility functions for component key generation
public enum HashUtils {
    
    /// Generate unique component key using FNV-1a hash algorithm
    /// - Parameters:
    ///   - name: Component name
    ///   - type: Component type
    /// - Returns: 32-bit hash value (never 0)
    public static func generateComponentKey(name: String, type: String) -> UInt32 {
        // FNV-1a hash algorithm for better collision resistance
        let combined = "\(name)_\(type)"
        var hash: UInt32 = 2166136261  // FNV offset basis for 32-bit
        for char in combined.utf8 {
            hash ^= UInt32(char)
            hash = hash &* 16777619  // FNV prime for 32-bit
        }
        
        // Ensure key is never 0 (reserved for invalid keys)
        return hash == 0 ? 1 : hash
    }
    
    /// Generate FNV-1a hash for any string input
    /// - Parameter input: String to hash
    /// - Returns: 32-bit hash value
    public static func fnv1aHash(_ input: String) -> UInt32 {
        var hash: UInt32 = 2166136261  // FNV offset basis for 32-bit
        for char in input.utf8 {
            hash ^= UInt32(char)
            hash = hash &* 16777619  // FNV prime for 32-bit
        }
        return hash
    }
}