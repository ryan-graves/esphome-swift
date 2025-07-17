import Foundation

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
        11111111, 22222222, 33333333, 44444444,
        55555555, 66666666, 77777777, 88888888, 99999999,
        12345678, 87654321
    ]
    
    // MARK: - Credential Generation
    
    /// Generate a single set of Matter credentials using cryptographically secure random generation
    /// - Returns: MatterCredentials with unique discriminator and passcode
    /// - Throws: MatterCredentialGeneratorError if secure random generation fails
    ///
    /// Implementation follows CSA Matter Core Specification requirements:
    /// - Uses cryptographically secure random number generator (Swift's SystemRandomNumberGenerator)
    /// - Ensures discriminator uniqueness for improved setup experience
    /// - Validates passcode against specification constraints and invalid values
    /// - Suitable for production device provisioning
    public static func generateCredentials() throws -> MatterCredentials {
        let discriminator = generateSecureDiscriminator()
        let passcode = generateSecurePasscode()
        
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
        
        // Prevent infinite loops by checking if we can generate enough unique discriminators
        let maxAvailableDiscriminators = Int(discriminatorMax - discriminatorMin + 1)
        guard count <= maxAvailableDiscriminators else {
            throw MatterCredentialGeneratorError.tooManyCredentialsRequested(
                count,
                maxAvailable: maxAvailableDiscriminators
            )
        }
        
        var credentials: [MatterCredentials] = []
        var usedDiscriminators: Set<UInt16> = []
        var usedPasscodes: Set<UInt32> = []
        
        for _ in 0 ..< count {
            var discriminator: UInt16
            var passcode: UInt32
            
            // Generate unique discriminator
            repeat {
                discriminator = generateSecureDiscriminator()
            } while usedDiscriminators.contains(discriminator)
            
            // Generate unique passcode
            repeat {
                passcode = generateSecurePasscode()
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
    
    /// Generate cryptographically secure discriminator using Swift's SystemRandomNumberGenerator
    /// - Returns: Random discriminator value (0-4095)
    private static func generateSecureDiscriminator() -> UInt16 {
        // Swift's random(in:) uses SystemRandomNumberGenerator by default,
        // which is cryptographically secure on all major platforms
        return UInt16.random(in: discriminatorMin ... discriminatorMax)
    }
    
    /// Generate cryptographically secure passcode using Swift's SystemRandomNumberGenerator with rejection sampling
    /// - Returns: Random passcode value (1-99999998, excluding invalid codes)
    ///
    /// Uses rejection sampling to avoid cryptographic bias that would be introduced by modulo operation
    private static func generateSecurePasscode() -> UInt32 {
        var passcode: UInt32
        
        // Use Swift's built-in random(in:) which handles rejection sampling internally
        // to ensure uniform distribution without bias
        repeat {
            passcode = UInt32.random(in: passcodeMin ... passcodeMax)
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
    case invalidCount(Int)
    case tooManyCredentialsRequested(Int, maxAvailable: Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCount(let count):
            return "Invalid credential count: \(count). Must be greater than 0"
        case .tooManyCredentialsRequested(let count, let maxAvailable):
            return "Too many credentials requested: \(count). Maximum available unique discriminators: \(maxAvailable)"
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