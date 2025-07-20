// Native Swift Embedded GPIO Switch Implementation

import ESP32Hardware
import SwiftEmbeddedCore

/// Restore mode for switch state after restart
public enum RestoreMode {
    case restoreDefaultOff
    case restoreDefaultOn
    case alwaysOff
    case alwaysOn
    case restoreInvertedDefaultOff
    case restoreInvertedDefaultOn
}

/// GPIO-based switch component
public struct GPIOSwitch: SwitchComponent {
    public let id: String
    public let name: String?
    private let pin: GPIO
    private let inverted: Bool
    private let restoreMode: RestoreMode
    public private(set) var state: Bool?
    
    public init(
        id: String,
        name: String? = nil,
        pin: GPIO,
        inverted: Bool = false,
        restoreMode: RestoreMode = .restoreDefaultOff
    ) {
        self.id = id
        self.name = name
        self.pin = pin
        self.inverted = inverted
        self.restoreMode = restoreMode
        self.state = initialState(for: restoreMode)
    }
    
    public mutating func setup() throws {
        // Configure pin as output
        try pin.setDirection(.output)
        
        // Set initial state
        if let initialState = state {
            applyState(initialState)
        }
        
        print("\(name ?? id) initialized: \(state ? "ON" : "OFF")")
    }
    
    public mutating func loop() throws {
        // Nothing to do in loop for basic switch
        // Could add debouncing or state verification here
    }
    
    public mutating func turnOn() throws {
        state = true
        applyState(true)
        reportState(true)
        print("\(name ?? id): ON")
    }
    
    public mutating func turnOff() throws {
        state = false
        applyState(false)
        reportState(false)
        print("\(name ?? id): OFF")
    }
    
    public mutating func toggle() throws {
        if state ?? false {
            try turnOff()
        } else {
            try turnOn()
        }
    }
    
    public func reportState(_ newState: Bool) {
        // Report to Home Assistant API or Matter
        // In real implementation: api_send_switch_state(id, newState)
    }
    
    private func applyState(_ state: Bool) {
        let level: GPIOLevel = inverted ? (state ? .low : .high) : (state ? .high : .low)
        pin.digitalWrite(level)
    }
    
    private func initialState(for mode: RestoreMode) -> Bool {
        switch mode {
        case .restoreDefaultOff, .restoreInvertedDefaultOff, .alwaysOff:
            return false
        case .restoreDefaultOn, .restoreInvertedDefaultOn, .alwaysOn:
            return true
        }
    }
}

/// Factory for creating GPIO switches from YAML configuration
public struct GPIOSwitchFactory: SwiftEmbeddedComponentFactory {
    public typealias ComponentType = GPIOSwitch
    
    public let platform = "gpio"
    
    public func createComponent(from config: [String: Any]) throws -> GPIOSwitch {
        guard let pinConfig = config["pin"] else {
            throw ComponentError.missingRequiredProperty("pin")
        }
        
        let pinNumber = try extractPinNumber(from: pinConfig)
        let id = config["id"] as? String ?? "gpio_switch_\(pinNumber)"
        let name = config["name"] as? String
        let inverted = config["inverted"] as? Bool ?? false
        let restoreMode = parseRestoreMode(config["restore_mode"] as? String)
        
        return GPIOSwitch(
            id: id,
            name: name,
            pin: GPIO(pinNumber),
            inverted: inverted,
            restoreMode: restoreMode
        )
    }
    
    private func extractPinNumber(from config: Any) throws -> UInt8 {
        if let number = config as? Int {
            return UInt8(number)
        } else if let str = config as? String {
            if str.hasPrefix("GPIO") {
                let numStr = str.dropFirst(4)
                if let num = UInt8(numStr) {
                    return num
                }
            }
        }
        throw ComponentError.invalidPropertyValue("pin", value: String(describing: config))
    }
    
    private func parseRestoreMode(_ mode: String?) -> RestoreMode {
        switch mode {
        case "RESTORE_DEFAULT_OFF": return .restoreDefaultOff
        case "RESTORE_DEFAULT_ON": return .restoreDefaultOn
        case "ALWAYS_OFF": return .alwaysOff
        case "ALWAYS_ON": return .alwaysOn
        case "RESTORE_INVERTED_DEFAULT_OFF": return .restoreInvertedDefaultOff
        case "RESTORE_INVERTED_DEFAULT_ON": return .restoreInvertedDefaultOn
        default: return .restoreDefaultOff
        }
    }
}

enum ComponentError: Error {
    case missingRequiredProperty(String)
    case invalidPropertyValue(String, value: String)
}