// Component Assembler for Swift Embedded Mode
// Generates main.swift from YAML configuration

import Foundation
import ESPHomeSwiftCore

/// Assembles Swift components from YAML configuration into compilable code
public class ComponentAssembler {
    
    public init() {}
    
    /// Generate complete main.swift file from configuration
    public func assembleMainFile(
        configuration: ESPHomeConfiguration
    ) throws -> String {
        var components: [String] = []
        var setupCalls: [String] = []
        var loopCalls: [String] = []
        
        // Process each component type
        if let sensors = configuration.sensor {
            for (index, sensor) in sensors.enumerated() {
                let componentInfo = try generateSensorComponent(sensor, index: index)
                components.append(componentInfo.declaration)
                setupCalls.append(componentInfo.setupCall)
                loopCalls.append(componentInfo.loopCall)
            }
        }
        
        if let switches = configuration.`switch` {
            for (index, sw) in switches.enumerated() {
                let componentInfo = try generateSwitchComponent(sw, index: index)
                components.append(componentInfo.declaration)
                setupCalls.append(componentInfo.setupCall)
                loopCalls.append(componentInfo.loopCall)
            }
        }
        
        if let lights = configuration.light {
            for (index, light) in lights.enumerated() {
                let componentInfo = try generateLightComponent(light, index: index)
                components.append(componentInfo.declaration)
                setupCalls.append(componentInfo.setupCall)
                loopCalls.append(componentInfo.loopCall)
            }
        }
        
        if let binarySensors = configuration.binarySensor {
            for (index, sensor) in binarySensors.enumerated() {
                let componentInfo = try generateBinarySensorComponent(sensor, index: index)
                components.append(componentInfo.declaration)
                setupCalls.append(componentInfo.setupCall)
                loopCalls.append(componentInfo.loopCall)
            }
        }
        
        // Generate the main.swift file
        return generateMainSwift(
            projectName: configuration.esphomeSwift.name,
            board: configuration.esp32.board,
            components: components,
            setupCalls: setupCalls,
            loopCalls: loopCalls,
            wifi: configuration.wifi,
            api: configuration.api,
            ota: configuration.ota
        )
    }
    
    // MARK: - Component Generation
    
    private func generateSensorComponent(
        _ sensor: SensorConfig,
        index: Int
    ) throws -> ComponentInfo {
        let id = sensor.id ?? "sensor_\(sensor.platform)_\(index)"
        let varName = id.camelCased()
        
        switch sensor.platform {
        case "dht":
            return try generateDHTSensor(sensor, varName: varName)
        case "adc":
            return try generateADCSensor(sensor, varName: varName)
        case "dallas":
            return try generateDallasSensor(sensor, varName: varName)
        default:
            throw ComponentAssemblyError.unsupportedPlatform(sensor.platform)
        }
    }
    
    private func generateDHTSensor(
        _ sensor: SensorConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let pin = sensor.pin else {
            throw ComponentAssemblyError.missingProperty("pin")
        }
        
        let model = sensor.model ?? "DHT22"
        let updateInterval = parseInterval(sensor.updateInterval)
        
        let declaration = """
        var \(varName) = try DHTSensor(
            id: "\(sensor.id ?? varName)",
            name: \(sensor.name.map { "\"\($0)\"" } ?? "nil"),
            pin: GPIO(\(pin.number)),
            model: .\(model.lowercased()),
            updateInterval: \(updateInterval)
        )
        """
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    private func generateADCSensor(
        _ sensor: SensorConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let pin = sensor.pin else {
            throw ComponentAssemblyError.missingProperty("pin")
        }
        
        let updateInterval = parseInterval(sensor.updateInterval)
        let attenuation = sensor.attenuation ?? "db11"
        
        var declaration = """
        var \(varName) = try ADCSensor(
            id: "\(sensor.id ?? varName)",
            name: \(sensor.name.map { "\"\($0)\"" } ?? "nil"),
            pin: GPIO(\(pin.number)),
            updateInterval: \(updateInterval),
            attenuation: .\(attenuation)
        """
        
        // Add voltage divider if configured
        if let vd = sensor.voltageDivider {
            declaration += """
            ,
            voltageDivider: ADCSensor.VoltageDivider(
                r1: \(vd.r1),
                r2: \(vd.r2)
            )
            """
        }
        
        // Add filters if configured
        if let filters = sensor.filters, !filters.isEmpty {
            let filterCode = generateFilters(filters)
            declaration += ",\n    filters: [\(filterCode)]"
        }
        
        declaration += ",\n    board: board\n)"
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    private func generateDallasSensor(
        _ sensor: SensorConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let pin = sensor.pin else {
            throw ComponentAssemblyError.missingProperty("pin")
        }
        
        let updateInterval = parseInterval(sensor.updateInterval)
        let address = sensor.address ?? "0x0000000000000000"
        
        let declaration = """
        var \(varName) = try DallasTemperatureSensor(
            id: "\(sensor.id ?? varName)",
            name: \(sensor.name.map { "\"\($0)\"" } ?? "nil"),
            pin: GPIO(\(pin.number)),
            address: \(address),
            updateInterval: \(updateInterval)
        )
        """
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    private func generateSwitchComponent(
        _ switch: SwitchConfig,
        index: Int
    ) throws -> ComponentInfo {
        let id = `switch`.id ?? "switch_\(`switch`.platform)_\(index)"
        let varName = id.camelCased()
        
        switch `switch`.platform {
        case "gpio":
            return try generateGPIOSwitch(`switch`, varName: varName)
        default:
            throw ComponentAssemblyError.unsupportedPlatform(`switch`.platform)
        }
    }
    
    private func generateGPIOSwitch(
        _ switch: SwitchConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let pin = `switch`.pin else {
            throw ComponentAssemblyError.missingProperty("pin")
        }
        
        let inverted = `switch`.inverted ?? false
        let restoreMode = `switch`.restoreMode ?? "RESTORE_DEFAULT_OFF"
        
        let declaration = """
        var \(varName) = try GPIOSwitch(
            id: "\(`switch`.id ?? varName)",
            name: \(`switch`.name.map { "\"\($0)\"" } ?? "nil"),
            pin: GPIO(\(pin.number)),
            inverted: \(inverted),
            restoreMode: .\(restoreMode.camelCased())
        )
        """
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    private func generateLightComponent(
        _ light: LightConfig,
        index: Int
    ) throws -> ComponentInfo {
        let id = light.id ?? "light_\(light.platform)_\(index)"
        let varName = id.camelCased()
        
        switch light.platform {
        case "rgb":
            return try generateRGBLight(light, varName: varName)
        case "monochromatic":
            return try generateMonochromaticLight(light, varName: varName)
        default:
            throw ComponentAssemblyError.unsupportedPlatform(light.platform)
        }
    }
    
    private func generateRGBLight(
        _ light: LightConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let redPin = light.redPin,
              let greenPin = light.greenPin,
              let bluePin = light.bluePin else {
            throw ComponentAssemblyError.missingProperty("RGB pins")
        }
        
        let frequency = light.frequency ?? 5000
        
        let declaration = """
        var \(varName) = try RGBLightComponent(
            id: "\(light.id ?? varName)",
            name: \(light.name.map { "\"\($0)\"" } ?? "nil"),
            redPin: GPIO(\(redPin.number)),
            greenPin: GPIO(\(greenPin.number)),
            bluePin: GPIO(\(bluePin.number)),
            frequency: \(frequency)
        )
        """
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    private func generateMonochromaticLight(
        _ light: LightConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let outputPin = light.output else {
            throw ComponentAssemblyError.missingProperty("output")
        }
        
        let declaration = """
        var \(varName) = try MonochromaticLight(
            id: "\(light.id ?? varName)",
            name: \(light.name.map { "\"\($0)\"" } ?? "nil"),
            pin: GPIO(\(outputPin.number))
        )
        """
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    private func generateBinarySensorComponent(
        _ sensor: BinarySensorConfig,
        index: Int
    ) throws -> ComponentInfo {
        let id = sensor.id ?? "binary_sensor_\(sensor.platform)_\(index)"
        let varName = id.camelCased()
        
        switch sensor.platform {
        case "gpio":
            return try generateGPIOBinarySensor(sensor, varName: varName)
        default:
            throw ComponentAssemblyError.unsupportedPlatform(sensor.platform)
        }
    }
    
    private func generateGPIOBinarySensor(
        _ sensor: BinarySensorConfig,
        varName: String
    ) throws -> ComponentInfo {
        guard let pin = sensor.pin else {
            throw ComponentAssemblyError.missingProperty("pin")
        }
        
        let inverted = sensor.inverted ?? false
        let mode = sensor.mode ?? "INPUT"
        
        let declaration = """
        var \(varName) = try GPIOBinarySensor(
            id: "\(sensor.id ?? varName)",
            name: \(sensor.name.map { "\"\($0)\"" } ?? "nil"),
            pin: GPIO(\(pin.number)),
            inverted: \(inverted),
            mode: .\(mode.lowercased())
        )
        """
        
        return ComponentInfo(
            declaration: declaration,
            setupCall: "try \(varName).setup()",
            loopCall: "try \(varName).loop()"
        )
    }
    
    // MARK: - Main File Generation
    
    private func generateMainSwift(
        projectName: String,
        board: String,
        components: [String],
        setupCalls: [String],
        loopCalls: [String],
        wifi: WiFiConfig?,
        api: APIConfig?,
        ota: OTAConfig?
    ) -> String {
        let componentDeclarations = components.joined(separator: "\n\n")
        let setupCallsJoined = setupCalls.map { "    \($0)" }.joined(separator: "\n")
        let loopCallsJoined = loopCalls.map { "        \($0)" }.joined(separator: "\n")
        
        var wifiSetup = ""
        if let wifi = wifi {
            wifiSetup = """
            
                // Initialize WiFi
                try WiFi.configure(
                    ssid: "\(wifi.ssid)",
                    password: "\(wifi.password)",
                    hostname: "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))"
                )
                try WiFi.connect()
            """
        }
        
        var apiSetup = ""
        if api != nil {
            apiSetup = """
            
                // Initialize API server
                try APIServer.start(port: 6053)
            """
        }
        
        var otaSetup = ""
        if let ota = ota {
            otaSetup = """
            
                // Initialize OTA updates
                try OTAUpdater.configure(
                    password: \(ota.password.map { "\"\($0)\"" } ?? "nil"),
                    port: \(ota.port ?? 3232)
                )
            """
        }
        
        return """
        // ESPHome Swift Generated Firmware
        // Board: \(board)
        // Generated: \(Date())
        
        import ESP32Hardware
        import SwiftEmbeddedCore
        import Components
        
        // Board configuration
        let board = "\(board)"
        
        // Component instances
        \(componentDeclarations)
        
        @main
        struct \(projectName.pascalCased())Firmware {
            static func main() throws {
                print("\\n=== \(projectName) Starting ===")
                print("Board: \\(board)")
                print("Free heap: \\(SystemInfo.freeHeap()) bytes")
                
                // Initialize hardware
                try initializeHardware()
                \(wifiSetup)\(apiSetup)\(otaSetup)
                
                // Setup components
                print("\\nInitializing components...")
        \(setupCallsJoined)
                
                print("\\nSetup complete! Entering main loop...")
                
                // Main event loop
                while true {
                    // Update components
        \(loopCallsJoined)
                    
                    // Feed watchdog
                    Watchdog.feed()
                    
                    // Small delay to prevent tight loop
                    Timer.delayMillis(10)
                }
            }
            
            static func initializeHardware() throws {
                // Initialize system components
                SystemTime.initialize()
                Watchdog.initialize(timeout: 10000)  // 10 second timeout
                
                // Board-specific initialization
                switch board {
                case "esp32-c6-devkitc-1":
                    // ESP32-C6 specific setup
                    print("Initializing ESP32-C6...")
                case "esp32-c3-devkitm-1":
                    // ESP32-C3 specific setup
                    print("Initializing ESP32-C3...")
                default:
                    print("Initializing generic ESP32...")
                }
            }
        }
        """
    }
    
    // MARK: - Helper Methods
    
    private func generateFilters(_ filters: [SensorFilter]) -> String {
        return filters.compactMap { filter in
            switch filter.type {
            case "moving_average":
                let window = filter.windowSize ?? 10
                return "MovingAverageFilter(windowSize: \(window))"
            case "calibrate_linear":
                guard let datapoints = filter.datapoints else { return nil }
                let points = datapoints.map { "(\($0.from), \($0.to))" }.joined(separator: ", ")
                return "CalibrationFilter(datapoints: [\(points)])"
            case "clamp":
                let min = filter.min ?? 0
                let max = filter.max ?? 100
                return "ClampFilter(min: \(min), max: \(max))"
            default:
                return nil
            }
        }.joined(separator: ", ")
    }
    
    private func parseInterval(_ interval: String?) -> UInt32 {
        guard let interval = interval else { return 60 }
        
        if interval.hasSuffix("s") {
            return UInt32(interval.dropLast()) ?? 60
        } else if interval.hasSuffix("ms") {
            return (UInt32(interval.dropLast(2)) ?? 60000) / 1000
        } else if interval.hasSuffix("min") {
            return (UInt32(interval.dropLast(3)) ?? 1) * 60
        }
        
        return UInt32(interval) ?? 60
    }
}

// MARK: - Supporting Types

struct ComponentInfo {
    let declaration: String
    let setupCall: String
    let loopCall: String
}

enum ComponentAssemblyError: LocalizedError {
    case unsupportedPlatform(String)
    case missingProperty(String)
    case invalidConfiguration(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform(let platform):
            return "Unsupported platform '\(platform)' for Swift Embedded mode"
        case .missingProperty(let property):
            return "Missing required property '\(property)' in component configuration"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
}

// String extensions for case conversion
extension String {
    func camelCased() -> String {
        let parts = self.split(separator: "_")
        guard !parts.isEmpty else { return self }
        
        let first = String(parts[0])
        let rest = parts.dropFirst().map { $0.capitalized }
        
        return ([first] + rest).joined()
    }
    
    func pascalCased() -> String {
        let parts = self.split(separator: "_")
        return parts.map { $0.capitalized }.joined()
    }
}