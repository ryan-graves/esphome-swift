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
        // Simplified implementation for Swift Embedded compilation
        // Real implementation would use: gpio_set_direction(gpio_num_t(number), direction.toESPIDF())
        guard number <= 30 else { return false } // ESP32-C6 has GPIO0-30
        print("GPIO\(number): Set direction to \(direction)")
        return true
    }
    
    /// Read digital value with simulated state
    private static var pinStates: [UInt8: Bool] = [:]
    
    public func digitalRead() -> Bool {
        // Simplified implementation with simulated pin states
        // Real implementation would use: gpio_get_level(gpio_num_t(number))
        return GPIO.pinStates[number] ?? false
    }
    
    /// Read digital value as GPIOLevel
    public func readLevel() -> GPIOLevel {
        return digitalRead() ? .high : .low
    }
    
    /// Write digital value
    public func digitalWrite(_ level: GPIOLevel) {
        // Simplified implementation with simulated pin states
        // Real implementation would use: gpio_set_level(gpio_num_t(number), level.toESPIDF())
        let high = (level == .high)
        GPIO.pinStates[number] = high
        print("GPIO\(number): Write \(level)")
    }
    
    /// Write digital value (boolean convenience)
    public func digitalWrite(_ high: Bool) {
        digitalWrite(high ? .high : .low)
    }
}

// ESP32-C6 GPIO pin definitions
extension GPIO {
    public static let pin0 = GPIO(0)
    public static let pin1 = GPIO(1)
    public static let pin2 = GPIO(2)
    public static let pin3 = GPIO(3)
    public static let pin4 = GPIO(4)
    public static let pin5 = GPIO(5)   // Default I2C SDA
    public static let pin6 = GPIO(6)   // Default I2C SCL
    public static let pin7 = GPIO(7)
    public static let pin8 = GPIO(8)
    public static let pin9 = GPIO(9)
    public static let pin10 = GPIO(10)
    public static let pin11 = GPIO(11)
    public static let pin12 = GPIO(12)
    public static let pin13 = GPIO(13)
    public static let pin14 = GPIO(14)
    public static let pin15 = GPIO(15)
    public static let pin16 = GPIO(16)
    public static let pin17 = GPIO(17)
    public static let pin18 = GPIO(18) // Input-only
    public static let pin19 = GPIO(19) // Input-only
    public static let pin20 = GPIO(20)
    public static let pin21 = GPIO(21)
    public static let pin22 = GPIO(22)
    public static let pin23 = GPIO(23)
    
    /// Check if pin is valid for ESP32-C6
    public func isValid() -> Bool {
        return number <= 23
    }
    
    /// Check if pin is input-only
    public func isInputOnly() -> Bool {
        return number == 18 || number == 19
    }
    
    /// Check if pin supports ADC
    public func supportsADC() -> Bool {
        return number <= 7 // GPIO0-7 are ADC1 channels
    }
    
    /// Check if pin supports PWM
    public func supportsPWM() -> Bool {
        return !isInputOnly() && isValid()
    }
}