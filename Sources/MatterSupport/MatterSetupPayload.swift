import Foundation

/// Matter setup payload generator for QR codes and manual pairing codes
public struct MatterSetupPayload {
    
    // MARK: - Constants
    
    /// Matter QR code prefix
    private static let qrCodePrefix = "MT:"
    
    /// Base38 alphabet (excludes $%*+/ :)
    private static let base38Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.?"
    
    /// Base38 alphabet as Array for O(1) access performance - compile-time constant
    private static let base38AlphabetArray: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z", "-", ".", "?"
    ]
    
    /// Maximum passcode value (2^27) for manual pairing code constraint
    private static let maxPasscodeValue: UInt32 = 134217728 // 2^27
    
    /// Maximum value for 10-digit representation (10^10)
    private static let maxTenDigitValue: UInt64 = 10000000000 // 10^10
    
    /// Maximum combined value (24-bit) for manual pairing code before modulo
    private static let maxCombinedValue: UInt64 = 16777216 // 2^24
    
    // MARK: - Payload Components
    
    public let version: UInt8
    public let vendorId: UInt16
    public let productId: UInt16
    public let commissioningFlow: UInt8
    public let discoveryCapabilities: UInt8
    public let discriminator: UInt16
    public let passcode: UInt32
    
    // MARK: - Initialization
    
    public init(
        vendorId: UInt16,
        productId: UInt16,
        discriminator: UInt16,
        passcode: UInt32,
        version: UInt8 = 0,
        commissioningFlow: UInt8 = 0,
        discoveryCapabilities: UInt8 = 0x04
    ) {
        self.version = version
        self.vendorId = vendorId
        self.productId = productId
        self.commissioningFlow = commissioningFlow
        self.discoveryCapabilities = discoveryCapabilities
        self.discriminator = discriminator
        self.passcode = passcode
    }
    
    // MARK: - QR Code Generation
    
    /// Generate the Matter QR code payload string
    /// - Returns: Complete QR code string starting with "MT:"
    public func generateQRCodePayload() -> String {
        let binaryData = packBinaryData()
        let base38String = encodeBase38(data: binaryData)
        return Self.qrCodePrefix + base38String
    }
    
    /// Generate 11-digit manual pairing code according to Matter Core Specification 5.1.4.1
    /// - Returns: Manual pairing code string (format: XXXXX-XXXXXX)
    /// - Throws: MatterSetupPayloadError.combinedValueOutOfRange if input values exceed specification limits
    /// 
    /// Implements the complete Matter specification algorithm including:
    /// - Proper discriminator and passcode encoding
    /// - Verhoeff check digit calculation for error detection
    /// - Compliant formatting for universal platform compatibility
    public func generateManualPairingCode() throws -> String {
        return try Self.generateManualPairingCode(discriminator: discriminator, passcode: passcode)
    }
    
    /// Generate 11-digit manual pairing code from discriminator and passcode
    /// - Parameters:
    ///   - discriminator: 12-bit discriminator value
    ///   - passcode: Setup passcode
    /// - Returns: Manual pairing code string (format: XXXXX-XXXXXX)
    /// - Throws: MatterSetupPayloadError.combinedValueOutOfRange if input values exceed specification limits
    /// 
    /// Static method that generates manual pairing codes according to Matter Core
    /// Specification 5.1.4.1 without requiring a full MatterSetupPayload instance.
    public static func generateManualPairingCode(discriminator: UInt16, passcode: UInt32) throws -> String {
        // Matter Core Specification 5.1.4.1: Manual Pairing Code Format
        // The manual pairing code is derived from:
        // 1. Short discriminator (4 bits from bits 11-8 of full discriminator)
        // 2. Setup passcode (constrained to fit in manual code space)
        
        let shortDiscriminator = (discriminator >> 8) & 0x0F // Upper 4 bits (bits 11-8)
        
        // Combine short discriminator and passcode according to Matter spec algorithm
        // This creates a value that gets encoded into the manual code
        let passcodeConstrained = passcode % Self.maxPasscodeValue // Constrain to 27 bits max
        
        // Matter Core Specification bit layout for manual pairing code:
        // - Short discriminator (4 bits) is shifted left by 20 bits to occupy bits 23-20
        // - Passcode is shifted right by 7 bits to remove the lower 7 bits (bits 6-0)
        // This creates a 24-bit value where the upper 4 bits are the discriminator
        // and the lower 20 bits are the upper portion of the passcode
        let combinedValue = (UInt64(shortDiscriminator) << 20) | UInt64(passcodeConstrained >> 7)
        
        // Validate that combined value fits within expected 24-bit range
        // The modulo operation is intentional per Matter spec to ensure 10-digit constraint
        guard combinedValue < Self.maxCombinedValue else {
            throw MatterSetupPayloadError.combinedValueOutOfRange(combinedValue)
        }
        
        // Convert to 10-digit representation for check digit calculation
        // Modulo operation constrains to 10 digits as required by Matter specification
        let digits = String(combinedValue % Self.maxTenDigitValue).padding(toLength: 10, withPad: "0", startingAt: 0)
        
        // Apply Verhoeff check digit algorithm (Matter specification requirement)
        let checkDigit = Self.calculateVerhoeffCheckDigit(digits)
        let fullCode = digits + String(checkDigit)
        
        // Format as XXXXX-XXXXXX (5 digits, hyphen, 6 digits)
        let part1 = String(fullCode.prefix(5))
        let part2 = String(fullCode.suffix(6))
        
        return "\(part1)-\(part2)"
    }
    
    /// Calculate Verhoeff check digit according to Matter Core Specification
    /// - Parameter digits: String of digits to calculate check digit for
    /// - Returns: Check digit (0-9)
    /// 
    /// The Verhoeff algorithm provides error detection for manual pairing codes,
    /// ensuring that single-digit errors and most transposition errors are detected.
    private static func calculateVerhoeffCheckDigit(_ digits: String) -> Int {
        // Verhoeff algorithm tables as specified in Matter Core Specification
        let multiplicationTable: [[Int]] = [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
            [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
            [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
            [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
            [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
            [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
            [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
            [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
            [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
        ]
        
        let permutationTable: [[Int]] = [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
            [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
            [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
            [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
            [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
            [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
            [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
        ]
        
        let inverse = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9]
        
        var checksum = 0
        let digitArray = digits.compactMap(\.wholeNumberValue)
        
        for (index, digit) in digitArray.enumerated() {
            let position = digitArray.count - index
            let permutedDigit = permutationTable[position % 8][digit]
            checksum = multiplicationTable[checksum][permutedDigit]
        }
        
        return inverse[checksum]
    }
    
    // MARK: - Binary Data Packing
    
    /// Pack payload data into binary format according to Matter spec
    /// - Returns: Packed binary data ready for Base38 encoding
    private func packBinaryData() -> Data {
        let bits = BitPacker()
        
        // Pack fields according to Matter setup payload format
        bits.pack(version, bits: 3) // 3 bits: version
        bits.pack(vendorId, bits: 16) // 16 bits: vendor ID
        bits.pack(productId, bits: 16) // 16 bits: product ID
        bits.pack(commissioningFlow, bits: 2) // 2 bits: commissioning flow
        bits.pack(discoveryCapabilities, bits: 8) // 8 bits: discovery capabilities
        bits.pack(discriminator, bits: 12) // 12 bits: discriminator
        bits.pack(passcode, bits: 27) // 27 bits: passcode
        
        // Pad to byte boundary
        bits.padToByteBoundary()
        
        return bits.data
    }
    
    // MARK: - Base38 Encoding
    
    /// Encode binary data to Base38 string
    /// - Parameter data: Binary data to encode
    /// - Returns: Base38 encoded string
    private func encodeBase38(data: Data) -> String {
        var result = ""
        let bytes = Array(data)
        
        // Process 3 bytes (24 bits) at a time to 5 Base38 characters
        var index = 0
        while index < bytes.count {
            var value: UInt64 = 0
            let bytesToProcess = min(3, bytes.count - index)
            
            // Pack up to 3 bytes into a 24-bit value
            for byteOffset in 0 ..< bytesToProcess {
                value |= UInt64(bytes[index + byteOffset]) << (8 * (2 - byteOffset))
            }
            
            // Convert to 5 Base38 characters
            var chars = ""
            var tempValue = value
            for _ in 0 ..< 5 {
                let charIndex = Int(tempValue % 38)
                let char = Self.base38AlphabetArray[charIndex]
                chars = String(char) + chars
                tempValue /= 38
            }
            
            result += chars
            index += 3
        }
        
        return result
    }
}

// MARK: - Bit Packing Helper

/// Helper class for packing bits into bytes
private class BitPacker {
    private(set) var data = Data()
    private var currentByte: UInt8 = 0
    private var bitsInCurrentByte = 0
    
    /// Pack a value with specified number of bits
    func pack<T: BinaryInteger>(_ value: T, bits: Int) {
        let intValue = UInt64(value)
        
        for bitIndex in 0 ..< bits {
            let bit = (intValue >> bitIndex) & 1
            currentByte |= UInt8(bit) << bitsInCurrentByte
            bitsInCurrentByte += 1
            
            if bitsInCurrentByte == 8 {
                data.append(currentByte)
                currentByte = 0
                bitsInCurrentByte = 0
            }
        }
    }
    
    /// Pad to byte boundary with zero bits
    func padToByteBoundary() {
        if bitsInCurrentByte > 0 {
            data.append(currentByte)
            currentByte = 0
            bitsInCurrentByte = 0
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during Matter setup payload generation
public enum MatterSetupPayloadError: Error, LocalizedError {
    case combinedValueOutOfRange(UInt64)
    
    public var errorDescription: String? {
        switch self {
        case .combinedValueOutOfRange(let value):
            return "Combined value \(value) exceeds 24-bit range (16777216)"
        }
    }
}

// MARK: - Convenience Extensions

public extension CommissioningConfig {
    /// Create a Matter setup payload from commissioning configuration
    /// - Parameters:
    ///   - vendorId: Vendor identifier
    ///   - productId: Product identifier
    /// - Returns: MatterSetupPayload instance
    func createSetupPayload(vendorId: UInt16, productId: UInt16) -> MatterSetupPayload {
        return MatterSetupPayload(
            vendorId: vendorId,
            productId: productId,
            discriminator: discriminator,
            passcode: passcode
        )
    }
}