// Native Swift Embedded RGB Light Implementation

import ESP32Hardware
import SwiftEmbeddedCore

/// RGB light effects
public enum LightEffect {
    case solid
    case breathing(period: UInt32)
    case rainbow(speed: UInt32)
    case strobe(onTime: UInt32, offTime: UInt32)
    case fade(colors: [(r: Float, g: Float, b: Float)], duration: UInt32)
}

/// RGB light component using PWM
public struct RGBLightComponent: Component {
    public let id: String
    public let name: String?
    private var rgbLED: RGBLED
    private var brightness: Float = 1.0
    private var isOn: Bool = false
    private var currentColor: (r: Float, g: Float, b: Float) = (0, 0, 0)
    private var targetColor: (r: Float, g: Float, b: Float) = (0, 0, 0)
    private var effect: LightEffect = .solid
    private var effectStartTime: UInt32 = 0
    
    public init(
        id: String,
        name: String? = nil,
        redPin: GPIO,
        greenPin: GPIO,
        bluePin: GPIO,
        frequency: UInt32 = 5000
    ) throws {
        self.id = id
        self.name = name
        self.rgbLED = try RGBLED(
            redPin: redPin,
            greenPin: greenPin,
            bluePin: bluePin,
            frequency: frequency
        )
    }
    
    public mutating func setup() throws {
        try rgbLED.setup()
        print("\(name ?? id) RGB light initialized")
    }
    
    public mutating func loop() throws {
        guard isOn else { return }
        
        switch effect {
        case .solid:
            // Static color, nothing to update
            break
            
        case .breathing(let period):
            updateBreathingEffect(period: period)
            
        case .rainbow(let speed):
            updateRainbowEffect(speed: speed)
            
        case .strobe(let onTime, let offTime):
            updateStrobeEffect(onTime: onTime, offTime: offTime)
            
        case .fade(let colors, let duration):
            updateFadeEffect(colors: colors, duration: duration)
        }
    }
    
    /// Turn light on with optional color
    public mutating func turnOn(color: (r: Float, g: Float, b: Float)? = nil) throws {
        isOn = true
        if let color = color {
            targetColor = color
        }
        try applyColor()
        print("\(name ?? id): ON - RGB(\(targetColor.r), \(targetColor.g), \(targetColor.b))")
    }
    
    /// Turn light off
    public mutating func turnOff() throws {
        isOn = false
        try rgbLED.setColor(red: 0, green: 0, blue: 0)
        print("\(name ?? id): OFF")
    }
    
    /// Set brightness (0.0 to 1.0)
    public mutating func setBrightness(_ brightness: Float) throws {
        self.brightness = max(0, min(1, brightness))
        if isOn {
            try applyColor()
        }
    }
    
    /// Set color
    public mutating func setColor(red: Float, green: Float, blue: Float) throws {
        targetColor = (red, green, blue)
        if isOn {
            try applyColor()
        }
    }
    
    /// Set color from hex
    public mutating func setColorHex(_ hex: UInt32) throws {
        let red = Float((hex >> 16) & 0xFF) / 255.0
        let green = Float((hex >> 8) & 0xFF) / 255.0
        let blue = Float(hex & 0xFF) / 255.0
        try setColor(red: red, green: green, blue: blue)
    }
    
    /// Set light effect
    public mutating func setEffect(_ effect: LightEffect) {
        self.effect = effect
        self.effectStartTime = SystemTime.millis()
    }
    
    // MARK: - Private methods
    
    private mutating func applyColor() throws {
        currentColor = targetColor
        try rgbLED.setColor(
            red: currentColor.r * brightness,
            green: currentColor.g * brightness,
            blue: currentColor.b * brightness
        )
    }
    
    private mutating func updateBreathingEffect(period: UInt32) {
        let elapsed = SystemTime.millis() - effectStartTime
        let phase = Float(elapsed % period) / Float(period)
        let intensity = (sin(phase * 2 * Float.pi) + 1) / 2
        
        do {
            try rgbLED.setColor(
                red: targetColor.r * intensity * brightness,
                green: targetColor.g * intensity * brightness,
                blue: targetColor.b * intensity * brightness
            )
        } catch {
            print("Breathing effect error: \(error)")
        }
    }
    
    private mutating func updateRainbowEffect(speed: UInt32) {
        let elapsed = SystemTime.millis() - effectStartTime
        let hue = Float(elapsed % speed) / Float(speed) * 360
        let (r, g, b) = hsvToRgb(h: hue, s: 1.0, v: 1.0)
        
        do {
            try rgbLED.setColor(
                red: r * brightness,
                green: g * brightness,
                blue: b * brightness
            )
        } catch {
            print("Rainbow effect error: \(error)")
        }
    }
    
    private mutating func updateStrobeEffect(onTime: UInt32, offTime: UInt32) {
        let elapsed = SystemTime.millis() - effectStartTime
        let cycleTime = onTime + offTime
        let phase = elapsed % cycleTime
        
        do {
            if phase < onTime {
                try applyColor()
            } else {
                try rgbLED.setColor(red: 0, green: 0, blue: 0)
            }
        } catch {
            print("Strobe effect error: \(error)")
        }
    }
    
    private mutating func updateFadeEffect(colors: [(r: Float, g: Float, b: Float)], duration: UInt32) {
        guard !colors.isEmpty else { return }
        
        let elapsed = SystemTime.millis() - effectStartTime
        let totalDuration = duration * UInt32(colors.count)
        let cycleElapsed = elapsed % totalDuration
        let colorIndex = Int(cycleElapsed / duration)
        let colorPhase = Float(cycleElapsed % duration) / Float(duration)
        
        let currentColorIndex = colorIndex % colors.count
        let nextColorIndex = (colorIndex + 1) % colors.count
        
        let current = colors[currentColorIndex]
        let next = colors[nextColorIndex]
        
        // Interpolate between colors
        let r = current.r + (next.r - current.r) * colorPhase
        let g = current.g + (next.g - current.g) * colorPhase
        let b = current.b + (next.b - current.b) * colorPhase
        
        do {
            try rgbLED.setColor(
                red: r * brightness,
                green: g * brightness,
                blue: b * brightness
            )
        } catch {
            print("Fade effect error: \(error)")
        }
    }
}

// Helper function to convert HSV to RGB
private func hsvToRgb(h: Float, s: Float, v: Float) -> (Float, Float, Float) {
    let c = v * s
    let x = c * (1 - abs(fmod(h / 60, 2) - 1))
    let m = v - c
    
    var r: Float = 0, g: Float = 0, b: Float = 0
    
    switch Int(h / 60) {
    case 0: (r, g, b) = (c, x, 0)
    case 1: (r, g, b) = (x, c, 0)
    case 2: (r, g, b) = (0, c, x)
    case 3: (r, g, b) = (0, x, c)
    case 4: (r, g, b) = (x, 0, c)
    case 5: (r, g, b) = (c, 0, x)
    default: break
    }
    
    return (r + m, g + m, b + m)
}

// Simple fmod implementation for embedded
private func fmod(_ x: Float, _ y: Float) -> Float {
    return x - Float(Int(x / y)) * y
}