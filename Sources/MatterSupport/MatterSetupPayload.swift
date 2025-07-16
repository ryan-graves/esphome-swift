import Foundation

/// Matter setup payload generator for QR codes and manual pairing codes
public struct MatterSetupPayload {
    
    // MARK: - Constants
    
    /// Matter QR code prefix
    private static let qrCodePrefix = "MT:"
    
    /// Base38 alphabet (excludes $%*+/ :)
    private static let base38Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.?"
    
    /// Standard payload version
    private static let payloadVersion: UInt8 = 0
    
    /// Standard commissioning flow (basic)
    private static let commissioningFlow: UInt8 = 0
    
    /// Discovery capabilities (BLE, WiFi, on network)
    private static let discoveryCapabilities: UInt8 = 0x04  // On IP network
    
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
    
    /// Generate 11-digit manual pairing code
    /// - Returns: Manual pairing code string (format: 11111-222222)
    public func generateManualPairingCode() -> String {
        // Manual pairing code combines discriminator (4 bits) and passcode
        let shortDiscriminator = (discriminator >> 8) & 0x0F  // Upper 4 bits
        
        // Encode discriminator + passcode into 11-digit code
        // This is a simplified implementation - real implementation would use
        // the Matter specification's exact algorithm
        let code = String(format: "%04d-%06d", shortDiscriminator, passcode % 1000000)
        return code
    }
    
    // MARK: - Binary Data Packing
    
    /// Pack payload data into binary format according to Matter spec
    /// - Returns: Packed binary data ready for Base38 encoding
    private func packBinaryData() -> Data {
        let bits = BitPacker()
        
        // Pack fields according to Matter setup payload format
        bits.pack(version, bits: 3)                    // 3 bits: version
        bits.pack(vendorId, bits: 16)                  // 16 bits: vendor ID
        bits.pack(productId, bits: 16)                 // 16 bits: product ID
        bits.pack(commissioningFlow, bits: 2)          // 2 bits: commissioning flow
        bits.pack(discoveryCapabilities, bits: 8)      // 8 bits: discovery capabilities
        bits.pack(discriminator, bits: 12)             // 12 bits: discriminator
        bits.pack(passcode, bits: 27)                  // 27 bits: passcode
        
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
        var i = 0
        while i < bytes.count {
            var value: UInt64 = 0
            let bytesToProcess = min(3, bytes.count - i)
            
            // Pack up to 3 bytes into a 24-bit value
            for j in 0..<bytesToProcess {
                value |= UInt64(bytes[i + j]) << (8 * (2 - j))
            }
            
            // Convert to 5 Base38 characters
            var chars = ""
            var tempValue = value
            for _ in 0..<5 {
                let index = Int(tempValue % 38)
                let char = Self.base38Alphabet[Self.base38Alphabet.index(Self.base38Alphabet.startIndex, offsetBy: index)]
                chars = String(char) + chars
                tempValue /= 38
            }
            
            result += chars
            i += 3
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
        
        for i in 0..<bits {
            let bit = (intValue >> i) & 1
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