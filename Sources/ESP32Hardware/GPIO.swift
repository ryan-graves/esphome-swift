// ESP32 GPIO Hardware Abstraction Layer for Swift Embedded

/// GPIO pin direction
public enum GPIODirection {
    case input
    case output
    case inputPullUp
    case inputPullDown
    case disabled
}

/// GPIO pin level
public enum GPIOLevel {
    case low
    case high
}

/// ESP32 GPIO pin abstraction
public struct GPIO {
    public let number: UInt8
    
    public init(_ number: UInt8) {
        self.number = number
    }
    
    /// Configure pin direction
    public func setDirection(_ direction: GPIODirection) -> Bool {
        // In real implementation, this would interface with ESP-IDF
        // gpio_set_direction(gpio_num_t(number), direction.toESPIDF())
        return true
    }
    
    /// Read digital value
    public func digitalRead() -> Bool {
        // In real implementation: gpio_get_level(gpio_num_t(number))
        return false // Placeholder
    }
    
    /// Read digital value as GPIOLevel
    public func readLevel() -> GPIOLevel {
        return digitalRead() ? .high : .low
    }
    
    /// Write digital value
    public func digitalWrite(_ level: GPIOLevel) {
        // In real implementation: gpio_set_level(gpio_num_t(number), level.toESPIDF())
    }
    
    /// Write digital value (boolean convenience)
    public func digitalWrite(_ high: Bool) {
        digitalWrite(high ? .high : .low)
    }
}

// Common ESP32 GPIO pins
extension GPIO {
    public static let pin0 = GPIO(0)
    public static let pin1 = GPIO(1)
    public static let pin2 = GPIO(2)
    public static let pin3 = GPIO(3)
    public static let pin4 = GPIO(4)
    public static let pin5 = GPIO(5)
    public static let pin6 = GPIO(6)
    public static let pin7 = GPIO(7)
    // ... more pins
}