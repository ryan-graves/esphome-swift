// GPIO Binary Sensor Swift Embedded Implementation

import ESP32Hardware

/// GPIO-based binary sensor for reading digital inputs (buttons, switches, etc.)
public struct GPIOBinarySensor: BinarySensorComponent {
    public let id: String
    public let name: String?
    public let pin: GPIO
    public let inverted: Bool
    public let pullMode: GPIODirection
    
    public var state: Bool? = nil
    private var lastState: Bool? = nil
    private var lastReadTime: UInt32 = 0
    private let debounceTime: UInt32 = 50 // 50ms debounce
    
    public init(
        id: String,
        name: String? = nil,
        pin: GPIO,
        inverted: Bool = false,
        pullMode: GPIODirection = .inputPullUp
    ) {
        self.id = id
        self.name = name
        self.pin = pin
        self.inverted = inverted
        self.pullMode = pullMode
    }
    
    public mutating func setup() -> Bool {
        // Configure pin as input with pull resistor
        let success = pin.setDirection(pullMode)
        
        // Read initial state
        if success {
            state = readState()
            lastState = state
        }
        
        return success
    }
    
    public mutating func loop() -> Bool {
        let currentTime = SystemTime.millisSinceStart()
        
        // Debounce readings
        if currentTime - lastReadTime >= debounceTime {
            let newState = readState()
            
            // Check for state change
            if newState != lastState {
                state = newState
                lastState = newState
                if let currentState = newState {
                    reportState(currentState)
                }
            }
            
            lastReadTime = currentTime
        }
        
        return true
    }
    
    public mutating func readState() -> Bool? {
        let digitalValue = pin.digitalRead()
        let logicalValue = inverted ? !digitalValue : digitalValue
        return logicalValue
    }
    
    public func reportState(_ newState: Bool) {
        // In real implementation, this would report to Home Assistant API
        print("Binary Sensor \(id): \(newState ? "ON" : "OFF")")
    }
}