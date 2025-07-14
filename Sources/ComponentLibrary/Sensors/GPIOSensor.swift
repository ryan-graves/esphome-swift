import Foundation
import ESPHomeSwiftCore

/// GPIO-based analog sensor factory
public struct GPIOSensorFactory: ComponentFactory {
    public typealias ConfigType = SensorConfig
    
    public let platform = "adc"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "update_interval", "accuracy", "filters"]
    
    public init() {
        // No longer store pinValidator as instance variable - create board-specific validator per call
    }
    
    public func validate(config: SensorConfig, board: String) throws {
        // Validate required pin
        guard let pin = config.pin else {
            throw ComponentValidationError.missingRequiredProperty(
                component: platform,
                property: "pin"
            )
        }
        
        // Create board-specific pin validator
        guard let boardDef = BoardCapabilities.boardDefinition(for: board) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "board",
                value: board,
                reason: "Unsupported board. Use 'swift run esphome-swift boards' to see available boards."
            )
        }
        
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        try pinValidator.validatePin(pin, requirements: .adc)
    }
    
    public func generateCode(config: SensorConfig, context: CodeGenerationContext) throws -> ComponentCode {
        // Create board-specific pin validator for code generation
        guard let boardDef = BoardCapabilities.boardDefinition(for: context.targetBoard) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "board",
                value: context.targetBoard,
                reason: "Unsupported board"
            )
        }
        
        let pinValidator = PinValidator(boardConstraints: boardDef.pinConstraints)
        let pinNumber = try pinValidator.extractPinNumber(from: config.pin!)
        let componentId = config.id ?? "adc_sensor_\(pinNumber)"
        let updateInterval = parseUpdateInterval(config.updateInterval ?? "60s")
        
        let headerIncludes = [
            "#include \"driver/adc.h\""
        ]
        
        let globalDeclarations = [
            "unsigned long \(componentId)_last_update = 0;",
            "const unsigned long \(componentId)_update_interval = \(updateInterval);"
        ]
        
        let setupCode = [
            "adc1_config_width(ADC_WIDTH_BIT_12);",
            "adc1_config_channel_atten(ADC1_CHANNEL_\(adcChannelForPin(pinNumber)), ADC_ATTEN_DB_11);"
        ]
        
        let loopCode = [
            """
            if (millis() - \(componentId)_last_update > \(componentId)_update_interval) {
                int \(componentId)_raw = adc1_get_raw(ADC1_CHANNEL_\(adcChannelForPin(pinNumber)));
                float \(componentId)_voltage = \(componentId)_raw * (3.3 / 4095.0);
                
                // TODO: Apply filters if configured
                // TODO: Send value via API
                printf("ADC Pin \(pinNumber): %.3fV (raw: %d)\\n", \(componentId)_voltage, \(componentId)_raw);
                
                \(componentId)_last_update = millis();
            }
            """
        ]
        
        return ComponentCode(
            headerIncludes: headerIncludes,
            globalDeclarations: globalDeclarations,
            setupCode: setupCode,
            loopCode: loopCode
        )
    }
    
    private func adcChannelForPin(_ pin: Int) -> Int {
        // Map GPIO pin to ADC1 channel - varies by board
        // For ESP32-C6: pins 0-7 map to ADC1 channels 0-7
        // TODO: Make this board-specific based on BoardCapabilities
        return pin
    }
    
    private func parseUpdateInterval(_ interval: String) -> Int {
        // Parse interval like "60s", "1000ms" to milliseconds
        if interval.hasSuffix("s") {
            let seconds = Int(interval.dropLast()) ?? 60
            return seconds * 1000
        } else if interval.hasSuffix("ms") {
            return Int(interval.dropLast(2)) ?? 60000
        } else {
            return Int(interval) ?? 60000
        }
    }
}