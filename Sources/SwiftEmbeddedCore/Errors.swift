// Swift Embedded Core Error Types

/// Base error type for Swift Embedded components
public enum ComponentError {
    case setupFailed(component: String, reason: String)
    case loopFailed(component: String, reason: String)
    case invalidConfiguration(component: String, property: String, value: String)
    case hardwareError(component: String, description: String)
    case communicationError(component: String, description: String)
    case notImplemented(feature: String)
}

/// Hardware-specific errors
public enum HardwareError {
    case gpioError(pin: UInt8, operation: String)
    case i2cError(address: UInt8, operation: String)
    case spiError(device: String, operation: String)
    case adcError(channel: UInt8, reason: String)
    case pwmError(channel: UInt8, reason: String)
    case wifiError(operation: String, reason: String)
}

/// Sensor-specific errors
public enum SensorError {
    case readingFailed(sensor: String, reason: String)
    case outOfRange(sensor: String, value: Float, min: Float, max: Float)
    case timeout(sensor: String)
    case invalidReading(sensor: String)
}