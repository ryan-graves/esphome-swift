// ESP32 I2C Hardware Abstraction Layer for Swift Embedded

/// I2C communication errors
public enum I2CError {
    case initializationFailed
    case communicationTimeout
    case nackReceived
    case invalidAddress
}

/// I2C bus abstraction
public struct I2C {
    public let sda: GPIO
    public let scl: GPIO
    public let frequency: UInt32
    
    public init(sda: GPIO, scl: GPIO, frequency: UInt32 = 100_000) {
        self.sda = sda
        self.scl = scl
        self.frequency = frequency
    }
    
    /// Initialize I2C bus
    public func initialize() -> Bool {
        // Simplified implementation for Swift Embedded compilation
        // Real implementation would use ESP-IDF i2c_master_init()
        
        // Configure pins for I2C
        _ = sda.setDirection(.inputPullUp)
        _ = scl.setDirection(.inputPullUp)
        
        print("I2C: Initialized on SDA=GPIO\(sda.number), SCL=GPIO\(scl.number) at \(frequency)Hz")
        
        // Validate pin assignment for ESP32-C6
        guard sda.number != scl.number else {
            print("I2C Error: SDA and SCL cannot use the same pin")
            return false
        }
        return true
    }
    
    /// Write data to I2C device
    public func write(address: UInt8, data: [UInt8]) -> Bool {
        // Simplified implementation for Swift Embedded compilation
        // Real implementation would use: i2c_master_write_to_device()
        guard address <= 0x7F else {
            print("I2C Error: Invalid address 0x\(String(address, radix: 16, uppercase: true))")
            return false
        }
        print("I2C: Write to 0x\(String(address, radix: 16, uppercase: true)) - \(data.count) bytes: \(data.map { String($0, radix: 16, uppercase: true) }.joined(separator: " "))")
        return true
    }
    
    /// Read data from I2C device
    public func read(address: UInt8, bytes: Int) -> [UInt8]? {
        // Simplified implementation with simulated sensor data
        // Real implementation would use: i2c_master_read_from_device()
        guard address <= 0x7F else {
            print("I2C Error: Invalid address 0x\(String(address, radix: 16, uppercase: true))")
            return nil
        }
        guard bytes > 0 else {
            return []
        }
        
        // Simulate realistic sensor data patterns
        let simulatedData = (0..<bytes).map { index in
            UInt8((index * 17 + Int(address)) % 256) // Deterministic but varied data
        }
        
        print("I2C: Read from 0x\(String(address, radix: 16, uppercase: true)) - \(bytes) bytes: \(simulatedData.map { String($0, radix: 16, uppercase: true) }.joined(separator: " "))")
        return simulatedData
    }
    
    /// Write then read (common pattern for sensors)
    public func writeRead(address: UInt8, writeData: [UInt8], readBytes: Int) -> [UInt8]? {
        guard write(address: address, data: writeData) else { return nil }
        return read(address: address, bytes: readBytes)
    }
}