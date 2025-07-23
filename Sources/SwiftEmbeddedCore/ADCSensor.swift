// ADC Sensor Swift Embedded Implementation

import ESP32Hardware

/// ADC-based analog sensor for voltage and current measurements
public struct ADCSensor: SensorComponent {
    public let id: String
    public let name: String?
    public let pin: GPIO
    public let updateInterval: UInt32
    public let attenuation: ADCAttenuation
    public let filters: [SensorFilter]
    
    public var state: Float? = nil
    private var lastReadTime: UInt32 = 0
    private var adcChannel: ADCChannel?
    
    public init(
        id: String,
        name: String? = nil,
        pin: GPIO,
        updateInterval: UInt32,
        attenuation: ADCAttenuation = .db11,
        filters: [SensorFilter] = [],
        board: String = "esp32-c6-devkitc-1"
    ) {
        self.id = id
        self.name = name
        self.pin = pin
        self.updateInterval = updateInterval
        self.attenuation = attenuation
        self.filters = filters
        
        // Get ADC channel for pin
        self.adcChannel = ADCHelper.channel(for: pin, board: board)
    }
    
    public mutating func setup() -> Bool {
        guard let channel = adcChannel else {
            return false
        }
        
        // Configure ADC channel
        return channel.configure(attenuation: attenuation, resolution: .bits12)
    }
    
    public mutating func loop() -> Bool {
        let currentTime = SystemTime.millisSinceStart()
        
        // Check if it's time to read
        if currentTime - lastReadTime >= updateInterval * 1000 {
            if let value = readValue() {
                state = value
                reportState(value)
                lastReadTime = currentTime
            }
        }
        
        return true
    }
    
    public mutating func readValue() -> Float? {
        guard let channel = adcChannel else {
            return nil
        }
        
        // Read raw ADC value
        guard let rawValue = channel.readRaw() else {
            return nil
        }
        
        // Convert to voltage
        var voltage = channel.rawToVoltage(rawValue, attenuation: attenuation)
        
        // Apply filters
        for filter in filters {
            voltage = filter.apply(voltage)
        }
        
        return voltage
    }
    
    public func reportState(_ newState: Float) {
        // In real implementation, this would report to Home Assistant API
        print("ADC \(id): \(newState)V")
    }
}

/// Sensor filter for processing ADC readings
public enum SensorFilter {
    case multiply(Float)
    case offset(Float)
    case slidingWindowAverage(Int)
    case exponentialMovingAverage(Float)
    
    public func apply(_ value: Float) -> Float {
        switch self {
        case .multiply(let factor):
            return value * factor
        case .offset(let offset):
            return value + offset
        case .slidingWindowAverage(_):
            // Simplified - would need state tracking for real implementation
            return value
        case .exponentialMovingAverage(_):
            // Simplified - would need state tracking for real implementation
            return value
        }
    }
}

/// ADC helper for channel mapping
public struct ADCHelper {
    public static func channel(for pin: GPIO, board: String) -> ADCChannel? {
        // Board-specific mapping - simplified for ESP32-C6
        switch pin.number {
        case 0...7:
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