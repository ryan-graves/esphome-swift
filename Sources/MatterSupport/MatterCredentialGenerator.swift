import Foundation
import Security

/// Generator for cryptographically secure Matter device credentials
/// Complies with CSA Matter Core Specification requirements for production devices
public struct MatterCredentialGenerator {
    
    // MARK: - Constants
    
    /// Minimum discriminator value (12-bit: 0-4095)
    private static let discriminatorMin: UInt16 = 0
    
    /// Maximum discriminator value (12-bit: 0-4095)
    private static let discriminatorMax: UInt16 = 4095
    
    /// Minimum passcode value per Matter specification (excludes invalid codes)
    private static let passcodeMin: UInt32 = 1
    
    /// Maximum passcode value per Matter specification (27-bit constraint)
    private static let passcodeMax: UInt32 = 99999998
    
    /// Invalid passcode values that must be avoided per Matter specification
    public static let invalidPasscodes: Set<UInt32> = [
        00000000, 11111111, 22222222, 33333333, 44444444,
        55555555, 66666666, 77777777, 88888888, 99999999,
        12345678, 87654321
    ]
    
    // MARK: - Credential Generation
    
    /// Generate a single set of Matter credentials using cryptographically secure random generation
    /// - Returns: MatterCredentials with unique discriminator and passcode
    /// - Throws: MatterCredentialGeneratorError if secure random generation fails
    ///
    /// Implementation follows CSA Matter Core Specification requirements:
    /// - Uses cryptographically secure random number generator (SecRandomCopyBytes)
    /// - Ensures discriminator uniqueness for improved setup experience
    /// - Validates passcode against specification constraints and invalid values
    /// - Suitable for production device provisioning
    public static func generateCredentials() throws -> MatterCredentials {
        let discriminator = try generateSecureDiscriminator()
        let passcode = try generateSecurePasscode()
        
        return MatterCredentials(
            discriminator: discriminator,
            passcode: passcode
        )
    }
    
    /// Generate multiple sets of Matter credentials for production device families
    /// - Parameter count: Number of credential sets to generate (must be > 0)
    /// - Returns: Array of unique MatterCredentials
    /// - Throws: MatterCredentialGeneratorError if generation fails or count is invalid
    ///
    /// Each generated set is guaranteed to have unique discriminator and passcode values
    /// to prevent commissioning conflicts in device families
    public static func generateCredentials(count: Int) throws -> [MatterCredentials] {
        guard count >= 1 else {
            throw MatterCredentialGeneratorError.invalidCount(count)
        }
        
        var credentials: [MatterCredentials] = []
        var usedDiscriminators: Set<UInt16> = []
        var usedPasscodes: Set<UInt32> = []
        
        for _ in 0 ..< count {
            var discriminator: UInt16
            var passcode: UInt32
            
            // Generate unique discriminator
            repeat {
                discriminator = try generateSecureDiscriminator()
            } while usedDiscriminators.contains(discriminator)
            
            // Generate unique passcode
            repeat {
                passcode = try generateSecurePasscode()
            } while usedPasscodes.contains(passcode)
            
            usedDiscriminators.insert(discriminator)
            usedPasscodes.insert(passcode)
            
            let credential = MatterCredentials(
                discriminator: discriminator,
                passcode: passcode
            )
            credentials.append(credential)
        }
        
        return credentials
    }
    
    // MARK: - Secure Random Generation
    
    /// Generate cryptographically secure discriminator using SecRandomCopyBytes
    /// - Returns: Random discriminator value (0-4095)
    /// - Throws: MatterCredentialGeneratorError.secureRandomFailed if generation fails
    private static func generateSecureDiscriminator() throws -> UInt16 {
        var bytes = [UInt8](repeating: 0, count: 2)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard status == errSecSuccess else {
            throw MatterCredentialGeneratorError.secureRandomFailed(status)
        }
        
        // Convert bytes to UInt16 and constrain to 12-bit range (0-4095)
        let value = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
        return value & 0x0FFF // Mask to 12 bits
    }
    
    /// Generate cryptographically secure passcode using SecRandomCopyBytes with rejection sampling
    /// - Returns: Random passcode value (1-99999998, excluding invalid codes)
    /// - Throws: MatterCredentialGeneratorError.secureRandomFailed if generation fails
    ///
    /// Uses rejection sampling to avoid cryptographic bias that would be introduced by modulo operation
    private static func generateSecurePasscode() throws -> UInt32 {
        let range = passcodeMax - passcodeMin + 1
        let maxValidValue = UInt32.max - (UInt32.max % range) // Largest value that divides evenly
        
        var passcode: UInt32
        
        repeat {
            // Generate uniformly distributed random value using rejection sampling
            var randomValue: UInt32
            repeat {
                var bytes = [UInt8](repeating: 0, count: 4)
                let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
                
                guard status == errSecSuccess else {
                    throw MatterCredentialGeneratorError.secureRandomFailed(status)
                }
                
                // Convert bytes to UInt32
                randomValue = UInt32(bytes[0]) |
                             (UInt32(bytes[1]) << 8) |
                             (UInt32(bytes[2]) << 16) |
                             (UInt32(bytes[3]) << 24)
                             
            } while randomValue >= maxValidValue // Reject values that would cause bias
            
            // Now we can safely use modulo without bias
            passcode = (randomValue % range) + passcodeMin
            
        } while invalidPasscodes.contains(passcode)
        
        return passcode
    }
    
    /// Validate that generated credentials meet Matter specification requirements
    /// - Parameter credentials: Credentials to validate
    /// - Returns: true if valid, false otherwise
    ///
    /// Validates:
    /// - Discriminator within 12-bit range (0-4095)
    /// - Passcode within specification range (1-99999998)
    /// - Passcode not in invalid code list
    public static func validateCredentials(_ credentials: MatterCredentials) -> Bool {
        // Validate discriminator range
        guard credentials.discriminator >= discriminatorMin &&
              credentials.discriminator <= discriminatorMax else {
            return false
        }
        
        // Validate passcode range
        guard credentials.passcode >= passcodeMin &&
              credentials.passcode <= passcodeMax else {
            return false
        }
        
        // Validate passcode not in invalid list
        guard !invalidPasscodes.contains(credentials.passcode) else {
            return false
        }
        
        return true
    }
}

// MARK: - Matter Credentials Model

/// Matter device credentials for commissioning
public struct MatterCredentials {
    /// 12-bit discriminator for device identification (0-4095)
    public let discriminator: UInt16
    
    /// 27-bit passcode for secure commissioning (1-99999998)
    public let passcode: UInt32
    
    public init(discriminator: UInt16, passcode: UInt32) {
        self.discriminator = discriminator
        self.passcode = passcode
    }
    
    /// Generate QR code payload for these credentials
    /// - Parameters:
    ///   - vendorId: Vendor identifier
    ///   - productId: Product identifier
    /// - Returns: Matter QR code payload string
    public func generateQRCode(vendorId: UInt16 = 0xFFF1, productId: UInt16 = 0x8001) -> String {
        let payload = MatterSetupPayload(
            vendorId: vendorId,
            productId: productId,
            discriminator: discriminator,
            passcode: passcode
        )
        return payload.generateQRCodePayload()
    }
    
    /// Generate manual pairing code for these credentials
    /// - Returns: 11-digit manual pairing code (format: XXXXX-XXXXXX)
    /// - Throws: MatterSetupPayloadError if generation fails
    public func generateManualPairingCode() throws -> String {
        return try MatterSetupPayload.generateManualPairingCode(
            discriminator: discriminator,
            passcode: passcode
        )
    }
}

// MARK: - Error Types

/// Errors that can occur during Matter credential generation
public enum MatterCredentialGeneratorError: Error, LocalizedError {
    case secureRandomFailed(OSStatus)
    case invalidCount(Int)
    
    public var errorDescription: String? {
        switch self {
        case .secureRandomFailed(let status):
            return "Secure random number generation failed with status: \(status)"
        case .invalidCount(let count):
            return "Invalid credential count: \(count). Must be greater than 0"
        }
    }
}

// MARK: - Output Formatting

public extension MatterCredentials {
    /// Format credentials as YAML configuration snippet
    var yamlFormat: String {
        return """
        # Matter commissioning credentials
        matter:
          commissioning:
            discriminator: \(discriminator)
            passcode: \(passcode)
        """
    }
    
    /// Format credentials as JSON
    var jsonFormat: String {
        return """
        {
          "discriminator": \(discriminator),
          "passcode": \(passcode)
        }
        """
    }
    
    /// Format credentials as human-readable text
    var textFormat: String {
        do {
            let manualCode = try generateManualPairingCode()
            let qrCode = generateQRCode()
            
            return """
            Matter Device Credentials
            ========================
            Discriminator: \(discriminator)
            Passcode: \(passcode)
            Manual Pairing Code: \(manualCode)
            QR Code: \(qrCode)
            
            SECURITY WARNING: Store these credentials securely.
            Each device must have unique credentials.
            """
        } catch {
            return """
            Matter Device Credentials
            ========================
            Discriminator: \(discriminator)
            Passcode: \(passcode)
            
            Error generating codes: \(error.localizedDescription)
            """
        }
    }
}

public extension [MatterCredentials] {
    /// Format multiple credentials as YAML array
    var yamlFormat: String {
        let credentialBlocks = self.enumerated().map { index, credential in
            """
            # Device \(index + 1) credentials
            matter:
              commissioning:
                discriminator: \(credential.discriminator)
                passcode: \(credential.passcode)
            """
        }
        return credentialBlocks.joined(separator: "\n\n")
    }
    
    /// Format multiple credentials as JSON array
    var jsonFormat: String {
        let jsonObjects = self.map { credential in
            """
              {
                "discriminator": \(credential.discriminator),
                "passcode": \(credential.passcode)
              }
            """
        }
        return "[\n" + jsonObjects.joined(separator: ",\n") + "\n]"
    }
    
    /// Format multiple credentials as human-readable text
    var textFormat: String {
        let credentialTexts = self.enumerated().map { index, credential in
            """
            Device \(index + 1):
              Discriminator: \(credential.discriminator)
              Passcode: \(credential.passcode)
            """
        }
        
        let header = """
        Matter Device Credentials (Generated \(count) sets)
        ===================================================
        
        SECURITY WARNING: Store these credentials securely.
        Each device must have unique credentials.
        
        """
        
        return header + credentialTexts.joined(separator: "\n")
    }
}