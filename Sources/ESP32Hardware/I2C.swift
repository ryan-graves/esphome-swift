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
    public func initialize() throws {
        // Configure pins for I2C
        try sda.setDirection(.inputPullUp)
        try scl.setDirection(.inputPullUp)
        
        // In real implementation: i2c_master_init() with ESP-IDF
    }
    
    /// Write data to I2C device
    public func write(address: UInt8, data: [UInt8]) throws {
        // In real implementation: i2c_master_write_to_device()
    }
    
    /// Read data from I2C device
    public func read(address: UInt8, bytes: Int) throws -> [UInt8] {
        // In real implementation: i2c_master_read_from_device()
        return Array(repeating: 0, count: bytes)
    }
    
    /// Write then read (common pattern for sensors)
    public func writeRead(address: UInt8, writeData: [UInt8], readBytes: Int) throws -> [UInt8] {
        try write(address: address, data: writeData)
        return try read(address: address, bytes: readBytes)
    }
}