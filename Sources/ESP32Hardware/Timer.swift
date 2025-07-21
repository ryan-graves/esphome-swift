// ESP32 Timer Hardware Abstraction Layer for Swift Embedded

/// Timer errors
public enum TimerError: Error {
    case initializationFailed
    case invalidFrequency
    case timerNotAvailable
}

/// Timer callback type
public typealias TimerCallback = () -> Void

/// Hardware timer abstraction
public struct HardwareTimer {
    public let id: UInt8
    private let callback: TimerCallback?
    
    public init(id: UInt8, callback: TimerCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    /// Initialize timer with frequency in Hz
    public func initialize(frequency: UInt32) throws {
        guard frequency > 0 && frequency <= 40_000_000 else {
            throw TimerError.invalidFrequency
        }
        
        // In real implementation: timer_config_t setup with ESP-IDF
        // esp_timer_create() and esp_timer_start_periodic()
    }
    
    /// Start periodic timer
    public func startPeriodic(intervalMicros: UInt64) throws {
        // esp_timer_start_periodic(timer, intervalMicros)
    }
    
    /// Start one-shot timer
    public func startOneShot(delayMicros: UInt64) throws {
        // esp_timer_start_once(timer, delayMicros)
    }
    
    /// Stop timer
    public func stop() {
        // esp_timer_stop(timer)
    }
    
    /// Delete timer
    public func delete() {
        // esp_timer_delete(timer)
    }
}

/// System time functions
public struct SystemTime {
    /// Get current time in microseconds since boot
    public static func micros() -> UInt64 {
        // In real implementation: esp_timer_get_time()
        return 0
    }
    
    /// Get current time in milliseconds since boot
    public static func millis() -> UInt32 {
        return UInt32(micros() / 1000)
    }
    
    /// Delay for specified microseconds
    public static func delayMicros(_ us: UInt32) {
        // In real implementation: ets_delay_us(us)
    }
    
    /// Delay for specified milliseconds
    public static func delayMillis(_ ms: UInt32) {
        // In real implementation: vTaskDelay(pdMS_TO_TICKS(ms))
    }
}

/// Watchdog timer control
public struct Watchdog {
    /// Initialize watchdog with timeout in seconds
    public static func initialize(timeoutSeconds: UInt32) {
        // esp_task_wdt_init(timeoutSeconds, true)
    }
    
    /// Feed the watchdog
    public static func feed() {
        // esp_task_wdt_reset()
    }
    
    /// Add current task to watchdog
    public static func addCurrentTask() {
        // esp_task_wdt_add(NULL)
    }
}