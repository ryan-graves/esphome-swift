import Foundation
import ArgumentParser
import ESPHomeSwiftCore
import ComponentLibrary
import MatterSupport
import SwiftEmbeddedGen
import Logging

/// Main CLI entry point for ESPHome Swift
@main
struct ESPHomeSwiftCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "esphome-swift",
        abstract: "ESPHome Swift - Generate Embedded Swift firmware for ESP32 microcontrollers",
        version: "0.1.0",
        subcommands: [
            BuildCommand.self,
            FlashCommand.self,
            MonitorCommand.self,
            ValidateCommand.self,
            ListComponentsCommand.self,
            NewProjectCommand.self,
            GenerateCredentialsCommand.self
        ]
    )
}

// MARK: - Build Command

struct BuildCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Build firmware from ESPHome Swift configuration"
    )
    
    @Argument(help: "Path to the ESPHome Swift YAML configuration file")
    var configPath: String
    
    @Option(name: .shortAndLong, help: "Output directory for generated project")
    var output: String = "./build"
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() throws {
        setupLogging(verbose: verbose)
        
        let logger = Logger(label: "BuildCommand")
        logger.info("Building project from: \\(configPath)")
        
        // Parse configuration
        let core = ESPHomeSwiftCore.shared
        let configuration = try core.parseConfiguration(file: configPath)
        
        logger.info("Building Swift Embedded firmware from: \\(configPath)")
        
        // Validate configuration for Swift Embedded
        try SwiftEmbeddedGen.validateConfiguration(configuration)
        
        // Generate Swift package
        let generatedPackage = try SwiftEmbeddedGen.generateProject(
            from: configuration,
            outputDirectory: output
        )
        
        logger.info("Generated Swift package at: \\(generatedPackage.path)")
        logger.info("Target: \\(generatedPackage.targetName)")
        logger.info("Executable: \\(generatedPackage.executableName)")
        
        // Build ESP32 firmware using ESP-IDF
        logger.info("Building ESP32 firmware using ESP-IDF...")
        
        // Check if ESP-IDF is available
        guard isESPIDFAvailable() else {
            logger.error("ESP-IDF not found. Please install ESP-IDF or use Docker:")
            logger.error("  docker compose run esp-shell")
            logger.error("See: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/")
            throw ExitCode.failure
        }
        
        let buildCommand = ["idf.py", "build"]
        
        if verbose {
            logger.debug("Build command: \\(buildCommand.joined(separator: \" \"))")
            logger.debug("Working directory: \\(generatedPackage.path)")
        }
        
        // Execute ESP-IDF build
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = buildCommand
        process.currentDirectoryURL = URL(fileURLWithPath: generatedPackage.path)
        
        // Set ESP-IDF environment variables
        var environment = ProcessInfo.processInfo.environment
        if let idfPath = environment["IDF_PATH"] {
            environment["PATH"] = "\(idfPath)/tools:\(environment["PATH"] ?? "")"
        }
        process.environment = environment
        
        if verbose {
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
        }
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            logger.error("ESP-IDF build failed with exit code: \\(process.terminationStatus)")
            logger.error("Try running the build in Docker environment:")
            logger.error("  docker compose run esp-shell")
            logger.error("  cd build/\\(generatedPackage.targetName) && idf.py build")
            throw ExitCode.failure
        }
        
        let binaryPath = "\\(generatedPackage.path)/build/\\(generatedPackage.targetName).bin" 
        logger.info("Build completed successfully!")
        logger.info("Firmware binary: \\(binaryPath)")
        logger.info("Project: \\(generatedPackage.path)")
        
        // Check if binary was created
        if !FileManager.default.fileExists(atPath: binaryPath) {
            logger.warning("Firmware binary not found at expected location.")
            logger.warning("Check build output for ESP-IDF compilation errors.")
            logger.info("You can also build manually using:")
            logger.info("  docker compose run esp-shell")
            logger.info("  cd build/\\(generatedPackage.targetName) && idf.py build")
        }
    }
    
    private func isESPIDFAvailable() -> Bool {
        // Check if idf.py is available in PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", "idf.py"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

// MARK: - Flash Command

struct FlashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Flash firmware to ESP32 device"
    )
    
    @Argument(help: "Path to the built project directory")
    var projectPath: String
    
    @Option(name: .shortAndLong, help: "Serial port (auto-detected if not specified)")
    var port: String?
    
    @Option(name: .shortAndLong, help: "Baud rate for flashing")
    var baudRate: Int = 460800
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() throws {
        setupLogging(verbose: verbose)
        
        let logger = Logger(label: "FlashCommand")
        logger.info("Flashing firmware from: \\(projectPath)")
        
        // TODO: Implement Swift Embedded binary flashing
        logger.error("Flash command not yet implemented for Swift Embedded binaries")
        logger.info("Please use ESP-IDF tools to flash the generated binary")
        throw ExitCode.failure
    }
}

// MARK: - Monitor Command

struct MonitorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Monitor serial output from ESP32 device"
    )
    
    @Argument(help: "Path to the built project directory")
    var projectPath: String
    
    @Option(name: .shortAndLong, help: "Serial port (auto-detected if not specified)")
    var port: String?
    
    @Option(name: .shortAndLong, help: "Baud rate for monitoring")
    var baudRate: Int = 115200
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() throws {
        setupLogging(verbose: verbose)
        
        let logger = Logger(label: "MonitorCommand")
        logger.info("Starting serial monitor for: \\(projectPath)")
        
        // TODO: Implement serial monitoring for Swift Embedded devices
        logger.error("Monitor command not yet implemented for Swift Embedded")
        logger.info("Please use a serial terminal like 'screen' or 'minicom'")
        throw ExitCode.failure
    }
}

// MARK: - Validate Command

struct ValidateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate ESPHome Swift configuration file"
    )
    
    @Argument(help: "Path to the ESPHome Swift YAML configuration file")
    var configPath: String
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() throws {
        setupLogging(verbose: verbose)
        
        let logger = Logger(label: "ValidateCommand")
        logger.info("Validating configuration: \\(configPath)")
        
        do {
            let core = ESPHomeSwiftCore.shared
            let configuration = try core.parseConfiguration(file: configPath)
            try core.validateConfiguration(configuration)
            
            // Validate for Swift Embedded (the only supported mode)
            try SwiftEmbeddedGen.validateConfiguration(configuration)
            logger.info("✅ Configuration is valid for Swift Embedded")
            
            logger.info("✅ Configuration is valid")
            print("Configuration validation passed!")
            
            // Print summary
            print("\\nProject Summary:")
            print("  Name: \\(configuration.esphomeSwift.name)")
            if let friendlyName = configuration.esphomeSwift.friendlyName {
                print("  Friendly Name: \\(friendlyName)")
            }
            print("  Board: \\(configuration.esp32.board)")
            print("  Framework: \\(configuration.esp32.framework.type.rawValue)")
            
            if let sensors = configuration.sensor {
                print("  Sensors: \\(sensors.count)")
            }
            if let switches = configuration.`switch` {
                print("  Switches: \\(switches.count)")
            }
            if let lights = configuration.light {
                print("  Lights: \\(lights.count)")
            }
            if let binarySensors = configuration.binary_sensor {
                print("  Binary Sensors: \\(binarySensors.count)")
            }
            
            // Swift Embedded info
            print("\\nSwift Embedded Mode:")
            print("  ⚠️  Requires Swift development snapshot with Embedded support")
            print("  📦 Generates Swift Package for ESP32 firmware")
            print("  🎯 Target triple: riscv32-none-none-eabi")
            
        } catch {
            logger.error("❌ Configuration validation failed: \\(error)")
            print("Configuration validation failed:")
            print(error.localizedDescription)
            throw ExitCode.failure
        }
    }
}

// MARK: - List Components Command

struct ListComponentsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-components",
        abstract: "List all available component platforms"
    )
    
    @Flag(name: .shortAndLong, help: "Show detailed component information")
    var detailed: Bool = false
    
    func run() throws {
        let registry = ComponentRegistry.shared
        print("Available Component Platforms:\\n")
        
        for factoryInfo in registry.allFactories {
            print("📦 \\(factoryInfo.platform) (\\(factoryInfo.componentType.rawValue))")
            
            if detailed {
                print("   Required: \\(factoryInfo.factory.requiredProperties.joined(separator: ", "))")
                print("   Optional: \\(factoryInfo.factory.optionalProperties.joined(separator: ", "))")
                print()
            }
        }
        
        if !detailed {
            print("\\nUse --detailed for more information about each component.")
        }
    }
}

// MARK: - New Project Command

struct NewProjectCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new ESPHome Swift project"
    )
    
    @Argument(help: "Project name")
    var name: String
    
    @Option(name: .shortAndLong, help: "Target board")
    var board: String = "esp32-c6-devkitc-1"
    
    @Option(name: .shortAndLong, help: "Output directory")
    var output: String = "."
    
    func run() throws {
        let projectPath = "\(output)/\(name)"
        
        // Create project directory
        try FileManager.default.createDirectory(
            atPath: projectPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Generate template configuration
        let template = generateProjectTemplate(name: name, board: board)
        let configPath = "\(projectPath)/\(name).yaml"
        
        try template.write(toFile: configPath, atomically: true, encoding: .utf8)
        
        print("✅ Created new ESPHome Swift project: \(name)")
        print("📁 Project directory: \(projectPath)")
        print("📄 Configuration file: \(configPath)")
        print("")
        print("Next steps:")
        print("  1. Edit \(configPath) to configure your device")
        print("  2. Run: esphome-swift build \(configPath)")
        print("  3. Run: esphome-swift flash \(projectPath)")
    }
}

// MARK: - Generate Credentials Command

struct GenerateCredentialsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-credentials",
        abstract: "Generate cryptographically secure Matter device credentials"
    )
    
    @Option(name: .shortAndLong, help: "Number of credential sets to generate")
    var count: Int = 1
    
    @Option(name: .shortAndLong, help: "Output format: yaml, json, or text")
    var format: OutputFormat = .text
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() throws {
        setupLogging(verbose: verbose)
        
        let logger = Logger(label: "GenerateCredentialsCommand")
        logger.info("Generating \(count) Matter credential set(s)...")
        
        do {
            let credentials: [MatterCredentials] = try count == 1 
                ? [MatterCredentialGenerator.generateCredentials()]
                : MatterCredentialGenerator.generateCredentials(count: count)
            
            // Output credentials in requested format
            let output = formatCredentials(credentials, format: format)
            print(output)
            
            // Security warning for production use
            if verbose {
                logger.info("✅ Generated \(credentials.count) credential set(s)")
            }
            logger.warning("🔒 Store these credentials securely - each device must have unique values")
            
        } catch {
            logger.error("❌ Credential generation failed: \(error)")
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
    
    private func formatCredentials(_ credentials: [MatterCredentials], format: OutputFormat) -> String {
        switch format {
        case .yaml:
            return credentials.count == 1 ? credentials[0].yamlFormat : credentials.yamlFormat
        case .json:
            return credentials.count == 1 ? credentials[0].jsonFormat : credentials.jsonFormat
        case .text:
            return credentials.count == 1 ? credentials[0].textFormat : credentials.textFormat
        }
    }
}

// MARK: - Output Format Enum

extension GenerateCredentialsCommand {
    enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
        case yaml = "yaml"
        case json = "json"
        case text = "text"
        
        var defaultValueDescription: String {
            return "text"
        }
    }
}

// MARK: - Helper Functions

/// Setup logging configuration
func setupLogging(verbose: Bool) {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = verbose ? .debug : .info
        return handler
    }
}

/// Generate project template
func generateProjectTemplate(name: String, board: String) -> String {
    return """
    esphome_swift:
      name: \(name)
      friendly_name: "\(name.capitalized)"
    
    esp32:
      board: \(board)
      framework:
        type: swift-embedded
    
    # Enable logging
    logger:
    
    # Enable WiFi (configure with your credentials)
    wifi:
      ssid: !secret wifi_ssid
      password: !secret wifi_password
      
      # Enable fallback hotspot (captive portal) in case WiFi connection fails
      ap:
        ssid: "\(name.capitalized) Fallback Hotspot"
        password: "12345678"
    
    # Enable Home Assistant API
    api:
      encryption:
        key: !secret api_encryption_key
    
    # Enable over-the-air updates
    ota:
      - platform: esphome_swift
    
    # Example sensor configuration
    # sensor:
    #   - platform: dht
    #     pin: GPIO4
    #     model: DHT22
    #     temperature:
    #       name: "Temperature"
    #     humidity:
    #       name: "Humidity"
    #     update_interval: 60s
    
    # Example switch configuration
    # switch:
    #   - platform: gpio
    #     pin: GPIO5
    #     name: "Relay"
    
    # Example light configuration
    # light:
    #   - platform: binary
    #     pin: GPIO2
    #     name: "Status LED"
    """
}