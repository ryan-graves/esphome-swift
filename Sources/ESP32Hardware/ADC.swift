// ESP32 ADC Hardware Abstraction Layer for Swift Embedded

/// ADC channel errors
public enum ADCError {
    case invalidChannel
    case invalidAttenuation
    case calibrationFailed
    case readTimeout
}

/// ADC attenuation settings (affects measurement range)
public enum ADCAttenuation {
    case db0 // 0dB attenuation, range: 0-950mV
    case db2_5 // 2.5dB attenuation, range: 0-1250mV
    case db6 // 6dB attenuation, range: 0-1750mV
    case db11 // 11dB attenuation, range: 0-3100mV
    
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
    case bits9 // 9-bit (0-511)
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
    public let unit: UInt8 // ADC unit (1 or 2)
    public let channel: UInt8 // Channel number
    public let pin: GPIO // Associated GPIO pin
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
    public func configure(attenuation: ADCAttenuation, resolution: ADCResolution) -> Bool {
        // Simplified implementation for Swift Embedded compilation
        // Real implementation would use: adc1_config_width(resolution) and adc1_config_channel_atten(channel,
        // attenuation)
        guard pin.supportsADC() else { 
            print("ADC Error: GPIO\(pin.number) does not support ADC")
            return false 
        }
        print("ADC\(unit)_CH\(channel): Configured for GPIO\(pin.number) with \(attenuation) attenuation")
        return true
    }
    
    /// Read raw ADC value with simulated noise
    public func readRaw() -> UInt16? {
        // Simplified implementation with simulated ADC readings
        // Real implementation would use: adc1_get_raw(channel)
        guard pin.supportsADC() else { return nil }
        
        // Simulate realistic ADC values with some variation
        let baseValue = UInt16(resolution.maxValue / 2) // Mid-range
        let noise = Int16.random(in: -100 ... 100) // Small random variation
        let rawValue = max(0, min(Int(resolution.maxValue), Int(baseValue) + Int(noise)))
        return UInt16(rawValue)
    }
    
    /// Read voltage in volts
    public func readVoltage() -> Float? {
        guard let raw = readRaw() else { return nil }
        let ratio = Float(raw) / Float(resolution.maxValue)
        return ratio * attenuation.maxVoltage
    }
    
    /// Convert raw value to voltage
    public func rawToVoltage(_ raw: UInt16, attenuation: ADCAttenuation) -> Float {
        let ratio = Float(raw) / Float(resolution.maxValue)
        return ratio * attenuation.maxVoltage
    }
    
    /// Read with averaging for stability
    public func readAveraged(samples: Int = 10) -> UInt16? {
        var sum: UInt32 = 0
        var validSamples = 0
        for _ in 0 ..< samples {
            if let raw = readRaw() {
                sum += UInt32(raw)
                validSamples += 1
            }
            SystemTime.delayMicros(100) // Small delay between samples
        }
        return validSamples > 0 ? UInt16(sum / UInt32(validSamples)) : nil
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
        // Simplified implementation for Swift Embedded compilation
        // Real implementation would use: esp_adc_cal_characterize()
        print("ADC\(unit): Created calibration for \(attenuation) with \(resolution)")
        return ADCCalibrationHandle(attenuation: attenuation, resolution: resolution)
    }
}

/// Calibration handle for accurate readings
public struct ADCCalibrationHandle {
    private let attenuation: ADCAttenuation
    private let resolution: ADCResolution
    
    init(attenuation: ADCAttenuation = .db11, resolution: ADCResolution = .bits12) {
        self.attenuation = attenuation
        self.resolution = resolution
    }
    
    /// Convert raw value to calibrated voltage
    public func rawToVoltage(_ raw: UInt16) -> Float {
        // Simplified implementation using attenuation and resolution
        // Real implementation would use: esp_adc_cal_raw_to_voltage()
        let ratio = Float(raw) / Float(resolution.maxValue)
        return ratio * attenuation.maxVoltage
    }
}

/// Helper to get ADC channel for a pin on specific board
public struct ADCMapper {
    /// Get ADC channel info for a GPIO pin
    public static func channel(for pin: GPIO, board: String) -> ADCChannel? {
        // Board-specific mapping
        // This would use BoardCapabilities to determine ADC support
        
        // Example for ESP32-C6:
        switch pin.number {
        case 0 ... 7:
            return ADCChannel(
                unit: 1,
                channel: pin.number,
                pin: pin
            )
        default:
            return nil
        }
    }
}