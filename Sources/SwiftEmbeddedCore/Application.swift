// Swift Embedded Application Framework

import ESP32Hardware

/// Main application class for Swift Embedded firmware
public class Application {
    private var loopInterval: UInt32 = 10 // milliseconds
    
    public init() {}
    
    /// Set main loop interval
    public func setLoopInterval(_ intervalMs: UInt32) {
        loopInterval = intervalMs
    }
    
    /// Initialize all components
    public func setup() -> Bool {
        // Initialize hardware
        guard initializeHardware() else {
            return false
        }
        
        // Initialize watchdog
        Watchdog.initialize(timeoutSeconds: 10)
        Watchdog.addCurrentTask()
        return true
    }
    
    /// Run the main application loop
    public func run() {
        while true {
            // Component loops will be called directly in generated main.swift
            // This is simplified for Swift Embedded constraints
            
            // Feed watchdog
            Watchdog.feed()
            
            // Delay before next iteration
            SystemTime.delayMillis(loopInterval)
        }
    }
    
    /// Initialize hardware peripherals
    private func initializeHardware() -> Bool {
        // Platform-specific hardware initialization
        // This would be implemented based on ESP-IDF requirements
        return true
    }
}

/// Global application instance
public var app = Application()