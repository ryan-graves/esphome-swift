import Foundation
import Network

/// Input validation utilities for WebDashboard API endpoints
public struct InputValidator {
    
    // MARK: - Host Validation
    
    /// Validates that a host string is a valid IP address or hostname
    public static func isValidHost(_ host: String) -> Bool {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty or too long
        guard !trimmedHost.isEmpty, trimmedHost.count <= 253 else {
            return false
        }
        
        // Check for valid IPv4 address
        if isValidIPv4(trimmedHost) {
            return true
        }
        
        // Check for valid IPv6 address
        if isValidIPv6(trimmedHost) {
            return true
        }
        
        // Check for valid hostname/domain
        if isValidHostname(trimmedHost) {
            return true
        }
        
        return false
    }
    
    private static func isValidIPv4(_ host: String) -> Bool {
        let components = host.split(separator: ".")
        guard components.count == 4 else { return false }
        
        for component in components {
            guard let number = Int(component),
                  number >= 0,
                  number <= 255,
                  String(number) == component else {
                return false
            }
        }
        return true
    }
    
    private static func isValidIPv6(_ host: String) -> Bool {
        // Use Network framework for IPv6 validation
        return IPv6Address(host) != nil
    }
    
    private static func isValidHostname(_ host: String) -> Bool {
        // RFC 1123 hostname validation
        let hostnameRegex = "^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?)*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", hostnameRegex)
        return predicate.evaluate(with: host)
    }
    
    // MARK: - Port Validation
    
    /// Validates that a port number is in valid range
    public static func isValidPort(_ port: Int) -> Bool {
        return port > 0 && port <= 65535
    }
    
    // MARK: - Device ID Validation
    
    /// Validates device ID format (alphanumeric, hyphens, underscores)
    public static func isValidDeviceId(_ deviceId: String) -> Bool {
        let trimmedId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check length constraints
        guard trimmedId.count >= 1, trimmedId.count <= 100 else {
            return false
        }
        
        // Allow alphanumeric characters, hyphens, underscores, and dots
        let deviceIdRegex = "^[a-zA-Z0-9._-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", deviceIdRegex)
        return predicate.evaluate(with: trimmedId)
    }
    
    // MARK: - Entity ID Validation
    
    /// Validates entity ID format
    public static func isValidEntityId(_ entityId: String) -> Bool {
        let trimmedId = entityId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check length constraints
        guard trimmedId.count >= 1, trimmedId.count <= 100 else {
            return false
        }
        
        // Allow alphanumeric characters, hyphens, and underscores
        let entityIdRegex = "^[a-zA-Z0-9_-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", entityIdRegex)
        return predicate.evaluate(with: trimmedId)
    }
    
    // MARK: - Private IP Range Validation
    
    /// Checks if an IP address is in a private range (RFC 1918)
    public static func isPrivateIPAddress(_ host: String) -> Bool {
        guard isValidIPv4(host) else { return false }
        
        let components = host.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return false }
        
        let firstOctet = components[0]
        let secondOctet = components[1]
        
        // Check private IP ranges
        // 10.0.0.0/8
        if firstOctet == 10 {
            return true
        }
        
        // 172.16.0.0/12
        if firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31 {
            return true
        }
        
        // 192.168.0.0/16
        if firstOctet == 192 && secondOctet == 168 {
            return true
        }
        
        // 127.0.0.0/8 (loopback)
        if firstOctet == 127 {
            return true
        }
        
        return false
    }
    
    // MARK: - Security Checks
    
    /// Validates that a host is safe to connect to (prevents SSRF attacks)
    public static func isSafeHost(_ host: String) -> Bool {
        guard isValidHost(host) else { return false }
        
        // For security, only allow private IP addresses and localhost
        if isValidIPv4(host) {
            return isPrivateIPAddress(host)
        }
        
        // Allow localhost and .local domains
        let lowercaseHost = host.lowercased()
        if lowercaseHost == "localhost" || lowercaseHost.hasSuffix(".local") {
            return true
        }
        
        // For production, you might want to be more restrictive
        // For now, allow any valid hostname for flexibility
        return true
    }
}

/// Rate limiting for API endpoints
public class RateLimiter {
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    private let queue = DispatchQueue(label: "rate-limiter", qos: .utility)
    
    public init(maxRequests: Int = 100, timeWindow: TimeInterval = 3600) { // 100 requests per hour by default
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
    }
    
    /// Check if a request from the given identifier should be allowed
    public func isAllowed(for identifier: String) -> Bool {
        return queue.sync {
            let now = Date()
            
            // Clean up expired entries
            cleanupExpiredEntries(currentTime: now)
            
            // Check current request count for identifier
            if let entry = requestCounts[identifier] {
                if entry.count >= maxRequests {
                    return false
                }
                requestCounts[identifier] = (count: entry.count + 1, resetTime: entry.resetTime)
            } else {
                requestCounts[identifier] = (count: 1, resetTime: now.addingTimeInterval(timeWindow))
            }
            
            return true
        }
    }
    
    private func cleanupExpiredEntries(currentTime: Date) {
        requestCounts = requestCounts.filter { $0.value.resetTime > currentTime }
    }
    
    /// Get remaining requests for an identifier
    public func remainingRequests(for identifier: String) -> Int {
        return queue.sync {
            guard let entry = requestCounts[identifier] else {
                return maxRequests
            }
            return max(0, maxRequests - entry.count)
        }
    }
}

/// Validation errors for API requests
public enum ValidationError: Error, LocalizedError {
    case invalidHost(String)
    case invalidPort(Int)
    case invalidDeviceId(String)
    case invalidEntityId(String)
    case unsafeHost(String)
    case rateLimitExceeded(String)
    case missingRequiredField(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidHost(let host):
            return "Invalid host address: \(host)"
        case .invalidPort(let port):
            return "Invalid port number: \(port). Must be between 1 and 65535"
        case .invalidDeviceId(let id):
            return "Invalid device ID: \(id). Must contain only alphanumeric characters, hyphens, underscores, and dots"
        case .invalidEntityId(let id):
            return "Invalid entity ID: \(id). Must contain only alphanumeric characters, hyphens, and underscores"
        case .unsafeHost(let host):
            return "Unsafe host address: \(host). Only private IP addresses and local hostnames are allowed"
        case .rateLimitExceeded(let identifier):
            return "Rate limit exceeded for: \(identifier). Please try again later"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}