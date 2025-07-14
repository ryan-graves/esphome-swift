import Foundation

// MARK: - Board Constraints Protocol

/// Protocol defining hardware constraints for different ESP32 boards
public protocol BoardConstraints {
    var availableGPIOPins: Set<Int> { get }
    var inputOnlyPins: Set<Int> { get }
    var outputCapablePins: Set<Int> { get }
    var pwmCapablePins: Set<Int> { get }
    var adcCapablePins: Set<Int> { get }
    var i2cDefaultSDA: Int { get }
    var i2cDefaultSCL: Int { get }
    var spiDefaultMOSI: Int { get }
    var spiDefaultMISO: Int { get }
    var spiDefaultCLK: Int { get }
    var spiDefaultCS: Int { get }
}

// MARK: - ESP32-C6 Board Constraints

/// ESP32-C6 specific hardware constraints
@frozen
public struct ESP32C6Constraints: BoardConstraints {
    public let availableGPIOPins: Set<Int> = Set(0 ... 30)
    public let inputOnlyPins: Set<Int> = [18, 19]
    public let outputCapablePins: Set<Int> = Set([
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30
    ])
    public let pwmCapablePins: Set<Int> = Set([
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30
    ])
    public let adcCapablePins: Set<Int> = Set(0 ... 7) // ADC1 only
    public let i2cDefaultSDA: Int = 5
    public let i2cDefaultSCL: Int = 6
    public let spiDefaultMOSI: Int = 7
    public let spiDefaultMISO: Int = 2
    public let spiDefaultCLK: Int = 6
    public let spiDefaultCS: Int = 10
    
    public init() {}
}

// MARK: - ESP32-C3 Board Constraints

/// ESP32-C3 specific hardware constraints
@frozen
public struct ESP32C3Constraints: BoardConstraints {
    public let availableGPIOPins: Set<Int> = Set(0 ... 21)
    public let inputOnlyPins: Set<Int> = [18, 19]
    public let outputCapablePins: Set<Int> = Set([
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        20, 21 // Skip 11-17 (flash), skip 18-19 (input only)
    ])
    public let pwmCapablePins: Set<Int> = Set([
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        20, 21
    ])
    public let adcCapablePins: Set<Int> = Set(0 ... 4) // ADC1 only
    public let i2cDefaultSDA: Int = 5
    public let i2cDefaultSCL: Int = 6
    public let spiDefaultMOSI: Int = 7
    public let spiDefaultMISO: Int = 2
    public let spiDefaultCLK: Int = 6
    public let spiDefaultCS: Int = 10
    
    public init() {}
}

// MARK: - ESP32-H2 Board Constraints

/// ESP32-H2 specific hardware constraints
@frozen
public struct ESP32H2Constraints: BoardConstraints {
    public let availableGPIOPins: Set<Int> = Set(0 ... 27) // 28 pins total (GPIO0-27)
    public let inputOnlyPins: Set<Int> = [] // ESP32-H2 has no input-only pins
    public let outputCapablePins: Set<Int> = Set(0 ... 23) // Skip 24-27 (flash/PSRAM)
    public let pwmCapablePins: Set<Int> = Set(0 ... 23)
    public let adcCapablePins: Set<Int> = Set(0 ... 4) // ADC1: GPIO0-4
    public let i2cDefaultSDA: Int = 1
    public let i2cDefaultSCL: Int = 0
    public let spiDefaultMOSI: Int = 7
    public let spiDefaultMISO: Int = 2
    public let spiDefaultCLK: Int = 6
    public let spiDefaultCS: Int = 10
    
    public init() {}
}

// MARK: - ESP32-P4 Board Constraints

/// ESP32-P4 specific hardware constraints
@frozen
public struct ESP32P4Constraints: BoardConstraints {
    public let availableGPIOPins: Set<Int> = Set(0 ... 54) // 55 pins total (GPIO0-54)
    public let inputOnlyPins: Set<Int> = [] // ESP32-P4 has no input-only pins
    public let outputCapablePins: Set<Int> = Set(0 ... 54) // All GPIO pins support output
    public let pwmCapablePins: Set<Int> = Set(0 ... 54) // All GPIO pins support PWM
    public let adcCapablePins: Set<Int> = Set([0, 1, 2, 3, 4, 5, 6, 7]) // ADC1: GPIO0-7
    public let i2cDefaultSDA: Int = 8
    public let i2cDefaultSCL: Int = 9
    public let spiDefaultMOSI: Int = 11
    public let spiDefaultMISO: Int = 13
    public let spiDefaultCLK: Int = 12
    public let spiDefaultCS: Int = 10
    
    public init() {}
}

// MARK: - Pin Requirements

/// Requirements for pin validation
public struct PinRequirements: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let input = PinRequirements(rawValue: 1 << 0)
    public static let output = PinRequirements(rawValue: 1 << 1)
    public static let pwm = PinRequirements(rawValue: 1 << 2)
    public static let adc = PinRequirements(rawValue: 1 << 3)
    public static let digital = PinRequirements(rawValue: 1 << 4)
    
    // Convenience combinations
    public static let inputOutput: PinRequirements = [.input, .output]
    public static let digitalOutput: PinRequirements = [.digital, .output]
    public static let analogInput: PinRequirements = [.adc, .input]
}

// MARK: - Pin Validation Errors

/// Errors that can occur during pin validation
public enum PinValidationError: Error, Equatable {
    case invalidFormat(String)
    case pinNotAvailable(Int)
    case pinNotCapableForRequirement(Int, PinRequirements)
    case inputOnlyPinUsedForOutput(Int)
    case adcPinNotAvailable(Int)
    case pwmPinNotAvailable(Int)
    
    public var localizedDescription: String {
        switch self {
        case .invalidFormat(let pin):
            return "Invalid pin format: '\(pin)'. Expected 'GPIO<number>' or integer."
        case .pinNotAvailable(let pin):
            return "GPIO\(pin) is not available on this board."
        case .pinNotCapableForRequirement(let pin, let requirements):
            return "GPIO\(pin) does not support required capabilities: \(requirements)."
        case .inputOnlyPinUsedForOutput(let pin):
            return "GPIO\(pin) is input-only and cannot be used for output."
        case .adcPinNotAvailable(let pin):
            return "GPIO\(pin) does not support ADC functionality."
        case .pwmPinNotAvailable(let pin):
            return "GPIO\(pin) does not support PWM functionality."
        }
    }
}

// MARK: - Pin Validator

/// Thread-safe pin validator for ESP32 boards
public struct PinValidator {
    private let boardConstraints: BoardConstraints
    
    public init(boardConstraints: BoardConstraints = ESP32C6Constraints()) {
        self.boardConstraints = boardConstraints
    }
    
    /// Extract GPIO pin number from PinConfig
    public func extractPinNumber(from pinConfig: PinConfig) throws -> Int {
        switch pinConfig.number {
        case .integer(let number):
            return number
        case .gpio(let gpioString):
            return try extractGPIONumber(from: gpioString)
        }
    }
    
    /// Extract GPIO number from string format (e.g., "GPIO4", "4")
    public func extractGPIONumber(from gpioString: String) throws -> Int {
        let cleaned = gpioString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Handle "GPIO<number>" format
        if cleaned.hasPrefix("GPIO") {
            let numberString = String(cleaned.dropFirst(4))
            guard let number = Int(numberString) else {
                throw PinValidationError.invalidFormat(gpioString)
            }
            return number
        }
        
        // Handle plain number format
        guard let number = Int(cleaned) else {
            throw PinValidationError.invalidFormat(gpioString)
        }
        
        return number
    }
    
    /// Validate a pin configuration against requirements
    public func validatePin(_ pinConfig: PinConfig, requirements: PinRequirements) throws {
        let pinNumber = try extractPinNumber(from: pinConfig)
        try validatePinNumber(pinNumber, requirements: requirements)
    }
    
    /// Validate a pin number against requirements
    public func validatePinNumber(_ pinNumber: Int, requirements: PinRequirements) throws {
        // Check if pin is available on this board
        guard boardConstraints.availableGPIOPins.contains(pinNumber) else {
            throw PinValidationError.pinNotAvailable(pinNumber)
        }
        
        // Check output capability for output requirements
        if requirements.contains(.output) {
            guard boardConstraints.outputCapablePins.contains(pinNumber) else {
                if boardConstraints.inputOnlyPins.contains(pinNumber) {
                    throw PinValidationError.inputOnlyPinUsedForOutput(pinNumber)
                } else {
                    throw PinValidationError.pinNotCapableForRequirement(pinNumber, requirements)
                }
            }
        }
        
        // Check PWM capability
        if requirements.contains(.pwm) {
            guard boardConstraints.pwmCapablePins.contains(pinNumber) else {
                throw PinValidationError.pwmPinNotAvailable(pinNumber)
            }
        }
        
        // Check ADC capability
        if requirements.contains(.adc) {
            guard boardConstraints.adcCapablePins.contains(pinNumber) else {
                throw PinValidationError.adcPinNotAvailable(pinNumber)
            }
        }
    }
    
    /// Validate multiple pins for conflicts
    public func validatePinConflicts(_ pinConfigs: [PinConfig]) throws {
        var usedPins: Set<Int> = []
        
        for pinConfig in pinConfigs {
            let pinNumber = try extractPinNumber(from: pinConfig)
            
            if usedPins.contains(pinNumber) {
                throw PinValidationError.pinNotAvailable(pinNumber) // Reusing existing error type
            }
            
            usedPins.insert(pinNumber)
        }
    }
    
    /// Get available pins for specific requirements
    public func getAvailablePins(for requirements: PinRequirements) -> Set<Int> {
        var availablePins = boardConstraints.availableGPIOPins
        
        if requirements.contains(.output) {
            availablePins = availablePins.intersection(boardConstraints.outputCapablePins)
        }
        
        if requirements.contains(.pwm) {
            availablePins = availablePins.intersection(boardConstraints.pwmCapablePins)
        }
        
        if requirements.contains(.adc) {
            availablePins = availablePins.intersection(boardConstraints.adcCapablePins)
        }
        
        return availablePins
    }
    
    /// Get board-specific default pins for I2C interface
    public func getDefaultI2CPins() -> (sda: Int, scl: Int) {
        return (
            sda: boardConstraints.i2cDefaultSDA,
            scl: boardConstraints.i2cDefaultSCL
        )
    }
    
    /// Get board-specific default SPI data pins  
    public func getDefaultSPIDataPins() -> (mosi: Int, miso: Int) {
        return (
            mosi: boardConstraints.spiDefaultMOSI,
            miso: boardConstraints.spiDefaultMISO
        )
    }
    
    /// Get board-specific default SPI control pins
    public func getDefaultSPIControlPins() -> (clk: Int, cs: Int) {
        return (
            clk: boardConstraints.spiDefaultCLK,
            cs: boardConstraints.spiDefaultCS
        )
    }
}

// MARK: - Board Constraints Usage

/// Recommended pattern for obtaining board-specific constraints
/// 
/// - Important: Use BoardCapabilities.boardDefinition(for:) for board-specific constraints.
///   This provides a more comprehensive board management system with capabilities and features.
/// 
/// - Example:
/// ```swift
/// guard let boardDef = BoardCapabilities.boardDefinition(for: boardName) else {
///     throw ComponentValidationError.invalidPropertyValue(
///         component: "component",
///         property: "board", 
///         value: boardName,
///         reason: "Unsupported board"
///     )
/// }
/// let constraints = boardDef.pinConstraints
/// ```