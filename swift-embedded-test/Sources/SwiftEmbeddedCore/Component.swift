// Core Component Protocol for Swift Embedded ESPHome Swift

/// Base protocol for all hardware components
public protocol Component {
    /// Component identifier
    var id: String { get }
    
    /// Component friendly name for display
    var name: String? { get }
    
    /// Setup component (called once at startup)
    mutating func setup() throws
    
    /// Component main loop (called repeatedly)
    mutating func loop() throws
}

/// Component with state reporting capability
public protocol StatefulComponent: Component {
    associatedtype State
    
    /// Current component state
    var state: State? { get }
    
    /// Report state change
    func reportState(_ newState: State)
}

/// Sensor component protocol
public protocol SensorComponent: StatefulComponent where State == Float {
    /// Update interval in seconds
    var updateInterval: UInt32 { get }
    
    /// Read sensor value
    mutating func readValue() throws -> Float?
}

/// Binary sensor component protocol  
public protocol BinarySensorComponent: StatefulComponent where State == Bool {
    /// Read binary state
    mutating func readState() throws -> Bool
}

/// Switch component protocol
public protocol SwitchComponent: StatefulComponent where State == Bool {
    /// Turn switch on
    mutating func turnOn() throws
    
    /// Turn switch off
    mutating func turnOff() throws
    
    /// Toggle switch state
    mutating func toggle() throws
}