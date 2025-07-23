// ESP32 PWM Hardware Abstraction Layer for Swift Embedded

/// PWM/LEDC errors
public enum PWMError {
    case invalidChannel
    case invalidFrequency
    case invalidDutyCycle
    case timerConfigFailed
}

/// PWM resolution in bits (affects duty cycle precision)
public enum PWMResolution {
    case bits8  // 0-255
    case bits10 // 0-1023
    case bits12 // 0-4095
    case bits14 // 0-16383
    case bits16 // 0-65535
    
    var maxDuty: UInt32 {
        switch self {
        case .bits8: return 255
        case .bits10: return 1023
        case .bits12: return 4095
        case .bits14: return 16383
        case .bits16: return 65535
        }
    }
    
    var bits: UInt8 {
        switch self {
        case .bits8: return 8
        case .bits10: return 10
        case .bits12: return 12
        case .bits14: return 14
        case .bits16: return 16
        }
    }
}

/// PWM channel for LED control
public struct PWMChannel {
    public let channel: UInt8
    public let pin: GPIO
    private let timer: UInt8
    private let frequency: UInt32
    private let resolution: PWMResolution
    private var currentDuty: UInt32 = 0
    
    public init?(
        channel: UInt8,
        pin: GPIO,
        frequency: UInt32 = 5000,
        resolution: PWMResolution = .bits12
    ) {
        guard channel < 8 else { // ESP32-C6 has 8 LEDC channels
            return nil
        }
        guard frequency >= 1 && frequency <= 40_000_000 else {
            return nil
        }
        
        self.channel = channel
        self.pin = pin
        self.timer = channel / 2  // Use 4 timers for 8 channels
        self.frequency = frequency
        self.resolution = resolution
    }
    
    /// Initialize PWM channel
    public func setup() -> Bool {
        // Configure timer
        // In real implementation:
        // ledc_timer_config_t timer_conf = {
        //     .speed_mode = LEDC_LOW_SPEED_MODE,
        //     .duty_resolution = resolution,
        //     .timer_num = timer,
        //     .freq_hz = frequency,
        //     .clk_cfg = LEDC_AUTO_CLK
        // }
        // ledc_timer_config(&timer_conf)
        
        // Configure channel
        // ledc_channel_config_t channel_conf = {
        //     .gpio_num = pin.number,
        //     .speed_mode = LEDC_LOW_SPEED_MODE,
        //     .channel = channel,
        //     .timer_sel = timer,
        //     .duty = 0,
        //     .hpoint = 0
        // }
        // ledc_channel_config(&channel_conf)
        return true
    }
    
    /// Set duty cycle (0.0 to 1.0)
    public mutating func setDuty(_ duty: Float) -> Bool {
        guard duty >= 0.0 && duty <= 1.0 else {
            return false
        }
        
        currentDuty = UInt32(duty * Float(resolution.maxDuty))
        
        // In real implementation:
        // ledc_set_duty(LEDC_LOW_SPEED_MODE, channel, currentDuty)
        // ledc_update_duty(LEDC_LOW_SPEED_MODE, channel)
        return true
    }
    
    /// Set raw duty cycle value
    public mutating func setDutyRaw(_ duty: UInt32) -> Bool {
        guard duty <= resolution.maxDuty else {
            return false
        }
        
        currentDuty = duty
        return true
        
        // In real implementation:
        // ledc_set_duty(LEDC_LOW_SPEED_MODE, channel, duty)
        // ledc_update_duty(LEDC_LOW_SPEED_MODE, channel)
    }
    
    /// Get current duty cycle (0.0 to 1.0)
    public func getDuty() -> Float {
        return Float(currentDuty) / Float(resolution.maxDuty)
    }
    
    /// Fade to duty cycle over duration
    public func fadeTo(duty: Float, durationMs: UInt32) -> Bool {
        guard duty >= 0.0 && duty <= 1.0 else {
            return false
        }
        
        let _ = UInt32(duty * Float(resolution.maxDuty))
        return true
        
        // In real implementation:
        // ledc_set_fade_time_and_start(
        //     LEDC_LOW_SPEED_MODE,
        //     channel,
        //     targetDuty,
        //     durationMs,
        //     LEDC_FADE_NO_WAIT
        // )
    }
    
    /// Stop PWM output
    public func stop() {
        // ledc_stop(LEDC_LOW_SPEED_MODE, channel, 0)
    }
}

/// RGB LED control using 3 PWM channels
public struct RGBLED {
    private var redChannel: PWMChannel
    private var greenChannel: PWMChannel
    private var blueChannel: PWMChannel
    
    public init?(
        redPin: GPIO,
        greenPin: GPIO,
        bluePin: GPIO,
        frequency: UInt32 = 5000
    ) {
        guard let red = PWMChannel(channel: 0, pin: redPin, frequency: frequency),
              let green = PWMChannel(channel: 1, pin: greenPin, frequency: frequency),
              let blue = PWMChannel(channel: 2, pin: bluePin, frequency: frequency) else {
            return nil
        }
        redChannel = red
        greenChannel = green
        blueChannel = blue
    }
    
    public func setup() -> Bool {
        return redChannel.setup() && greenChannel.setup() && blueChannel.setup()
    }
    
    /// Set RGB color (0.0 to 1.0 for each channel)
    public mutating func setColor(red: Float, green: Float, blue: Float) -> Bool {
        return redChannel.setDuty(red) && greenChannel.setDuty(green) && blueChannel.setDuty(blue)
    }
    
    /// Set color from hex value (0xRRGGBB)
    public mutating func setColorHex(_ hex: UInt32) throws {
        let red = Float((hex >> 16) & 0xFF) / 255.0
        let green = Float((hex >> 8) & 0xFF) / 255.0
        let blue = Float(hex & 0xFF) / 255.0
        try setColor(red: red, green: green, blue: blue)
    }
    
    /// Fade to color over duration
    public func fadeTo(red: Float, green: Float, blue: Float, durationMs: UInt32) -> Bool {
        return redChannel.fadeTo(duty: red, durationMs: durationMs) && greenChannel.fadeTo(duty: green, durationMs: durationMs) && blueChannel.fadeTo(duty: blue, durationMs: durationMs)
    }
}