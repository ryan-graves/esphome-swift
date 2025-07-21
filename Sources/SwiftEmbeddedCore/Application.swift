// Swift Embedded Application Framework

import ESP32Hardware

/// Main application class for Swift Embedded firmware
public class Application {
    private var components: [any Component] = []
    private var loopInterval: UInt32 = 10 // milliseconds
    
    public init() {}
    
    /// Add a component to the application
    public func addComponent(_ component: any Component) {
        components.append(component)
    }
    
    /// Set main loop interval
    public func setLoopInterval(_ intervalMs: UInt32) {
        loopInterval = intervalMs
    }
    
    /// Initialize all components
    public func setup() throws {
        // Initialize hardware
        try initializeHardware()
        
        // Setup all components
        for i in 0..<components.count {
            var component = components[i]
            do {
                try component.setup()
                components[i] = component
            } catch {
                throw ComponentError.setupFailed(
                    component: component.id,
                    reason: "\(error)"
                )
            }
        }
        
        // Initialize watchdog
        Watchdog.initialize(timeoutSeconds: 10)
        Watchdog.addCurrentTask()
    }
    
    /// Run the main application loop
    public func run() throws {
        while true {
            // Process all components
            for i in 0..<components.count {
                var component = components[i]
                do {
                    try component.loop()
                    components[i] = component
                } catch {
                    throw ComponentError.loopFailed(
                        component: component.id,
                        reason: "\(error)"
                    )
                }
            }
            
            // Feed watchdog
            Watchdog.feed()
            
            // Delay before next iteration
            SystemTime.delayMillis(loopInterval)
        }
    }
    
    /// Initialize hardware peripherals
    private func initializeHardware() throws {
        // Platform-specific hardware initialization
        // This would be implemented based on ESP-IDF requirements
    }
}

/// Global application instance
public var app = Application()