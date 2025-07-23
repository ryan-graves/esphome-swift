// GPIO Switch Swift Embedded Implementation

import ESP32Hardware

/// GPIO-based switch for controlling digital outputs
public struct GPIOSwitch: SwitchComponent {
    public let id: String
    public let name: String?
    public let pin: GPIO
    public let inverted: Bool
    
    public var state: Bool? = nil
    
    public init(
        id: String,
        name: String? = nil,
        pin: GPIO,
        inverted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.pin = pin
        self.inverted = inverted
    }
    
    public mutating func setup() -> Bool {
        // Configure pin as output
        let success = pin.setDirection(.output)
        
        // Set initial state to off
        if success {
            state = false
            let _ = turnOff()
        }
        
        return success
    }
    
    public mutating func loop() -> Bool {
        // Switches don't need periodic updates
        // They respond to commands
        return true
    }
    
    public mutating func turnOn() -> Bool {
        let outputLevel = inverted ? false : true
        pin.digitalWrite(outputLevel)
        state = true
        reportState(true)
        return true
    }
    
    public mutating func turnOff() -> Bool {
        let outputLevel = inverted ? true : false
        pin.digitalWrite(outputLevel)
        state = false
        reportState(false)
        return true
    }
    
    public mutating func toggle() -> Bool {
        if let currentState = state {
            return currentState ? turnOff() : turnOn()
        } else {
            return turnOn() // Default to on if state unknown
        }
    }
    
    public func reportState(_ newState: Bool) {
        // In real implementation, this would report to Home Assistant API
        print("Switch \(id): \(newState ? "ON" : "OFF")")
    }
}