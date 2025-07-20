// Native Swift Embedded ADC Sensor Implementation

import ESP32Hardware
import SwiftEmbeddedCore

/// ADC-based sensor component
public struct ADCSensor: SensorComponent {
    public let id: String
    public let name: String?
    public let updateInterval: UInt32
    private let channel: ADCChannel
    private var lastUpdateTime: UInt32 = 0
    public private(set) var state: Float?
    
    /// Voltage divider configuration for extended range
    public struct VoltageDivider {
        let r1: Float  // Upper resistor (to input)
        let r2: Float  // Lower resistor (to ground)
        
        /// Calculate actual voltage from ADC reading
        func actualVoltage(measured: Float) -> Float {
            return measured * ((r1 + r2) / r2)
        }
    }
    
    private let voltageDivider: VoltageDivider?
    private let filters: [SensorFilter]
    
    public init(
        id: String,
        name: String? = nil,
        pin: GPIO,
        updateInterval: UInt32 = 60,
        attenuation: ADCAttenuation = .db11,
        voltageDivider: VoltageDivider? = nil,
        filters: [SensorFilter] = [],
        board: String
    ) throws {
        self.id = id
        self.name = name
        self.updateInterval = updateInterval
        self.voltageDivider = voltageDivider
        self.filters = filters
        
        // Get ADC channel for pin on this board
        self.channel = try ADCMapper.channel(for: pin, board: board)
    }
    
    public mutating func setup() throws {
        try channel.configure()
        print("\(name ?? id) ADC sensor initialized on pin \(channel.pin.number)")
    }
    
    public mutating func loop() throws {
        let currentTime = SystemTime.millis()
        
        if currentTime - lastUpdateTime >= updateInterval * 1000 {
            if let value = try readValue() {
                state = value
                reportState(value)
            }
            lastUpdateTime = currentTime
        }
    }
    
    public mutating func readValue() throws -> Float? {
        // Read with averaging for stability
        var voltage = try channel.readAveraged(samples: 16).toVoltage()
        
        // Apply voltage divider if configured
        if let divider = voltageDivider {
            voltage = divider.actualVoltage(measured: voltage)
        }
        
        // Apply filters
        var filtered = voltage
        for filter in filters {
            filtered = filter.apply(filtered)
        }
        
        return filtered
    }
    
    public func reportState(_ newState: Float) {
        print("\(name ?? id): \(newState)V")
        // Report to API/Matter
    }
}

/// Sensor filters for processing readings
public protocol SensorFilter {
    func apply(_ value: Float) -> Float
}

/// Moving average filter
public struct MovingAverageFilter: SensorFilter {
    private var buffer: [Float]
    private let size: Int
    private var index: Int = 0
    private var filled: Bool = false
    
    public init(windowSize: Int) {
        self.size = windowSize
        self.buffer = Array(repeating: 0, count: windowSize)
    }
    
    public mutating func apply(_ value: Float) -> Float {
        buffer[index] = value
        index = (index + 1) % size
        
        if index == 0 {
            filled = true
        }
        
        let count = filled ? size : index
        let sum = buffer.prefix(count).reduce(0, +)
        return sum / Float(count)
    }
}

/// Calibration filter for linear correction
public struct CalibrationFilter: SensorFilter {
    let offset: Float
    let multiplier: Float
    
    public func apply(_ value: Float) -> Float {
        return (value * multiplier) + offset
    }
}

/// Clamp filter to limit value range
public struct ClampFilter: SensorFilter {
    let min: Float
    let max: Float
    
    public func apply(_ value: Float) -> Float {
        return Swift.min(Swift.max(value, min), max)
    }
}

// Extension to convert raw ADC to voltage
extension UInt16 {
    func toVoltage(resolution: ADCResolution = .bits12, attenuation: ADCAttenuation = .db11) -> Float {
        let ratio = Float(self) / Float(resolution.maxValue)
        return ratio * attenuation.maxVoltage
    }
}