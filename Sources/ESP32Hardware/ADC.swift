// ESP32 ADC Hardware Abstraction Layer for Swift Embedded

/// ADC channel errors
public enum ADCError: Error {
    case invalidChannel
    case invalidAttenuation
    case calibrationFailed
    case readTimeout
}

/// ADC attenuation settings (affects measurement range)
public enum ADCAttenuation {
    case db0    // 0dB attenuation, range: 0-950mV
    case db2_5  // 2.5dB attenuation, range: 0-1250mV
    case db6    // 6dB attenuation, range: 0-1750mV
    case db11   // 11dB attenuation, range: 0-3100mV
    
    var maxVoltage: Float {
        switch self {
        case .db0: return 0.95
        case .db2_5: return 1.25
        case .db6: return 1.75
        case .db11: return 3.1
        }
    }
}

/// ADC resolution in bits
public enum ADCResolution {
    case bits9  // 9-bit (0-511)
    case bits10 // 10-bit (0-1023)
    case bits11 // 11-bit (0-2047)
    case bits12 // 12-bit (0-4095)
    case bits13 // 13-bit (0-8191) - ESP32-S2/S3 only
    
    var maxValue: UInt16 {
        switch self {
        case .bits9: return 511
        case .bits10: return 1023
        case .bits11: return 2047
        case .bits12: return 4095
        case .bits13: return 8191
        }
    }
}

/// ADC channel abstraction
public struct ADCChannel {
    public let unit: UInt8      // ADC unit (1 or 2)
    public let channel: UInt8   // Channel number
    public let pin: GPIO        // Associated GPIO pin
    private let attenuation: ADCAttenuation
    private let resolution: ADCResolution
    
    public init(
        unit: UInt8,
        channel: UInt8,
        pin: GPIO,
        attenuation: ADCAttenuation = .db11,
        resolution: ADCResolution = .bits12
    ) {
        self.unit = unit
        self.channel = channel
        self.pin = pin
        self.attenuation = attenuation
        self.resolution = resolution
    }
    
    /// Configure ADC channel
    public func configure() throws {
        // In real implementation:
        // adc1_config_width(resolution)
        // adc1_config_channel_atten(channel, attenuation)
    }
    
    /// Read raw ADC value
    public func readRaw() throws -> UInt16 {
        // In real implementation:
        // return adc1_get_raw(channel)
        return 2048 // Simulated middle value
    }
    
    /// Read voltage in volts
    public func readVoltage() throws -> Float {
        let raw = try readRaw()
        let ratio = Float(raw) / Float(resolution.maxValue)
        return ratio * attenuation.maxVoltage
    }
    
    /// Read with averaging for stability
    public func readAveraged(samples: Int = 10) throws -> UInt16 {
        var sum: UInt32 = 0
        for _ in 0..<samples {
            sum += UInt32(try readRaw())
            SystemTime.delayMicros(100) // Small delay between samples
        }
        return UInt16(sum / UInt32(samples))
    }
}

/// ADC calibration support
public struct ADCCalibration {
    /// Create calibration handle for accurate voltage readings
    public static func createCalibration(
        unit: UInt8,
        attenuation: ADCAttenuation,
        resolution: ADCResolution
    ) throws -> ADCCalibrationHandle {
        // In real implementation: esp_adc_cal_characterize()
        return ADCCalibrationHandle()
    }
}

/// Calibration handle for accurate readings
public struct ADCCalibrationHandle {
    /// Convert raw value to calibrated voltage
    public func rawToVoltage(_ raw: UInt16) -> Float {
        // In real implementation: esp_adc_cal_raw_to_voltage()
        return Float(raw) * (3.3 / 4095.0)
    }
}

/// Helper to get ADC channel for a pin on specific board
public struct ADCMapper {
    /// Get ADC channel info for a GPIO pin
    public static func channel(for pin: GPIO, board: String) throws -> ADCChannel {
        // Board-specific mapping
        // This would use BoardCapabilities to determine ADC support
        
        // Example for ESP32-C6:
        switch pin.number {
        case 0...7:
            return ADCChannel(
                unit: 1,
                channel: pin.number,
                pin: pin
            )
        default:
            throw ADCError.invalidChannel
        }
    }
}