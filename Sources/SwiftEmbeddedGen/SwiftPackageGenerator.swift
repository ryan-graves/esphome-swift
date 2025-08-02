// Swift Package Generator for ESPHome Swift Embedded Mode

import Foundation
import ESPHomeSwiftCore

/// Generates Swift Package structure for embedded firmware
public class SwiftPackageGenerator {
    private let componentAssembler = ComponentAssembler()
    
    public init() {}
    
    /// Extract pin number from PinConfig for code generation
    private func extractPinNumber(_ pinConfig: PinConfig) -> Int {
        switch pinConfig.number {
        case .integer(let number):
            return number
        case .gpio(let gpioString):
            // Extract number from "GPIO4" format or return as-is if numeric
            let cleanString = gpioString.replacingOccurrences(of: "GPIO", with: "")
            return Int(cleanString) ?? 0
        }
    }
    
    /// Generate complete Swift package from configuration
    public func generatePackage(
        from configuration: ESPHomeConfiguration,
        outputDirectory: String
    ) throws -> GeneratedSwiftPackage {
        let projectName = configuration.esphomeSwift.name
        let projectPath = "\(outputDirectory)/\(projectName)"
        
        // Create package structure
        try createPackageStructure(at: projectPath)
        
        // Generate Package.swift
        let packageManifest = try generatePackageManifest(
            configuration: configuration,
            projectName: projectName
        )
        
        // Generate main.swift with assembled components
        let mainSwift = try componentAssembler.assembleMainFile(
            configuration: configuration
        )
        
        // Generate component sources
        let componentSources = try generateComponentSources(
            configuration: configuration
        )
        
        // Write all files
        try writePackageFiles(
            projectPath: projectPath,
            manifest: packageManifest,
            mainSwift: mainSwift,
            componentSources: componentSources
        )
        
        // Copy HAL source files
        try copyHALSources(to: projectPath)
        
        // Generate ESP-IDF project files
        try generateESPIDFProject(
            at: projectPath,
            configuration: configuration,
            projectName: projectName
        )
        
        return GeneratedSwiftPackage(
            path: projectPath,
            targetName: projectName,
            executableName: "\(projectName)Firmware"
        )
    }
    
    // MARK: - Private Methods
    
    private func createPackageStructure(at path: String) throws {
        let directories = [
            path,
            "\(path)/Sources",
            "\(path)/Sources/Firmware",
            "\(path)/Sources/Components",
            "\(path)/Sources/ESP32Hardware",
            "\(path)/Sources/SwiftEmbeddedCore",
            "\(path)/Resources",
            // ESP-IDF project structure
            "\(path)/main",
            "\(path)/components"
        ]
        
        for directory in directories {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func generatePackageManifest(
        configuration: ESPHomeConfiguration,
        projectName: String
    ) throws -> String {
        let board = configuration.esp32.board
        let targetTriple = getTargetTriple(for: board)
        
        return """
        // swift-tools-version: 5.9
        // ESPHome Swift Generated Package - \(Date())
        
        import PackageDescription
        
        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v13)],
            products: [
                .executable(
                    name: "\(projectName)Firmware",
                    targets: ["Firmware"]
                )
            ],
            dependencies: [
                // ESPHome Swift framework dependencies
                // These would be resolved from the main project
            ],
            targets: [
                .executableTarget(
                    name: "Firmware",
                    dependencies: [
                        "Components",
                        "ESP32Hardware",
                        "SwiftEmbeddedCore"
                    ],
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded"),
                        .unsafeFlags([
                            "-target", "\(targetTriple)"
                        ])
                    ],
                    linkerSettings: [
                        .unsafeFlags([
                            "-Xlinker", "-T",
                            "-Xlinker", "esp32c6.ld"
                        ])
                    ]
                ),
                .target(
                    name: "Components",
                    dependencies: ["ESP32Hardware", "SwiftEmbeddedCore"],
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded")
                    ]
                ),
                .target(
                    name: "ESP32Hardware",
                    dependencies: [],
                    path: "Sources/ESP32Hardware",
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded")
                    ]
                ),
                .target(
                    name: "SwiftEmbeddedCore",
                    dependencies: ["ESP32Hardware"],
                    path: "Sources/SwiftEmbeddedCore",
                    swiftSettings: [
                        .enableExperimentalFeature("Embedded")
                    ]
                )
            ]
        )
        """
    }
    
    private func generateComponentSources(
        configuration: ESPHomeConfiguration
    ) throws -> [ComponentSource] {
        var sources: [ComponentSource] = []
        
        // Generate component configuration structs
        let configSource = try generateComponentConfigs(configuration)
        sources.append(ComponentSource(
            fileName: "ComponentConfigs.swift",
            content: configSource
        ))
        
        // Copy required component implementations
        // In real implementation, this would copy actual component files
        
        return sources
    }
    
    private func generateComponentConfigs(
        _ configuration: ESPHomeConfiguration
    ) throws -> String {
        var configs = """
        // Auto-generated component configurations
        // Swift Embedded - no import statements needed
        
        """
        
        // Generate config structs for each component type
        if let sensors = configuration.sensor {
            for sensor in sensors {
                configs += generateSensorConfig(sensor)
            }
        }
        
        if let switches = configuration.`switch` {
            for sw in switches {
                configs += generateSwitchConfig(sw)
            }
        }
        
        return configs
    }
    
    private func generateSensorConfig(_ sensor: SensorConfig) -> String {
        let id = sensor.id ?? "sensor_\(sensor.platform)"
        return """
        
        struct \(id.camelCased())Config {
            static let platform = "\(sensor.platform)"
            static let pin = \(sensor.pin.map { "GPIO(\(extractPinNumber($0)))" } ?? "nil")
            static let name = "\(sensor.name ?? id)"
            static let updateInterval: UInt32 = \(parseInterval(sensor.updateInterval))
        }
        
        """
    }
    
    private func generateSwitchConfig(_ switch: SwitchConfig) -> String {
        let id = `switch`.id ?? "switch_\(`switch`.platform)"
        return """
        
        struct \(id.camelCased())Config {
            static let platform = "\(`switch`.platform)"
            static let pin = \(`switch`.pin.map { "GPIO(\(extractPinNumber($0)))" } ?? "nil")
            static let name = "\(`switch`.name ?? id)"
            static let inverted = \(`switch`.inverted ?? false)
        }
        
        """
    }
    
    private func writePackageFiles(
        projectPath: String,
        manifest: String,
        mainSwift: String,
        componentSources: [ComponentSource]
    ) throws {
        // Write Package.swift
        let manifestURL = URL(fileURLWithPath: "\(projectPath)/Package.swift")
        try manifest.write(to: manifestURL, atomically: true, encoding: .utf8)
        
        // Write main.swift
        let mainURL = URL(fileURLWithPath: "\(projectPath)/Sources/Firmware/firmware.swift")
        try mainSwift.write(to: mainURL, atomically: true, encoding: .utf8)
        
        // Write component sources
        for source in componentSources {
            let sourceURL = URL(fileURLWithPath: "\(projectPath)/Sources/Components/\(source.fileName)")
            try source.content.write(to: sourceURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func getTargetTriple(for board: String) -> String {
        // All current ESP32 RISC-V boards use 32-bit architecture
        return "riscv32-none-none-eabi"
    }
    
    private func parseInterval(_ interval: String?) -> UInt32 {
        guard let interval = interval else { return 60 }
        
        if interval.hasSuffix("s") {
            return UInt32(interval.dropLast()) ?? 60
        } else if interval.hasSuffix("ms") {
            return (UInt32(interval.dropLast(2)) ?? 60000) / 1000
        }
        
        return UInt32(interval) ?? 60
    }
    
    private func copyHALSources(to projectPath: String) throws {
        let fileManager = FileManager.default
        
        // Get the path to the HAL modules in the main project
        // This assumes the generator is running from the main project directory
        let currentDirectory = fileManager.currentDirectoryPath
        let esp32HardwarePath = "\(currentDirectory)/Sources/ESP32Hardware"
        let swiftEmbeddedCorePath = "\(currentDirectory)/Sources/SwiftEmbeddedCore"
        
        // Copy ESP32Hardware files
        if fileManager.fileExists(atPath: esp32HardwarePath) {
            let hardwareFiles = try fileManager.contentsOfDirectory(atPath: esp32HardwarePath)
            for file in hardwareFiles where file.hasSuffix(".swift") {
                let sourcePath = "\(esp32HardwarePath)/\(file)"
                let destPath = "\(projectPath)/Sources/ESP32Hardware/\(file)"
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
            }
        }
        
        // Copy SwiftEmbeddedCore files
        if fileManager.fileExists(atPath: swiftEmbeddedCorePath) {
            let coreFiles = try fileManager.contentsOfDirectory(atPath: swiftEmbeddedCorePath)
            for file in coreFiles where file.hasSuffix(".swift") {
                let sourcePath = "\(swiftEmbeddedCorePath)/\(file)"
                let destPath = "\(projectPath)/Sources/SwiftEmbeddedCore/\(file)"
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
            }
        }
    }
    
    // MARK: - ESP-IDF Project Generation
    
    private func generateESPIDFProject(
        at projectPath: String,
        configuration: ESPHomeConfiguration,
        projectName: String
    ) throws {
        let board = configuration.esp32.board
        
        // Generate main CMakeLists.txt
        let mainCMake = generateMainCMakeLists(projectName: projectName, board: board)
        let mainCMakeURL = URL(fileURLWithPath: "\(projectPath)/CMakeLists.txt")
        try mainCMake.write(to: mainCMakeURL, atomically: true, encoding: .utf8)
        
        // Generate main/CMakeLists.txt
        let mainComponentCMake = generateMainComponentCMakeLists()
        let mainComponentURL = URL(fileURLWithPath: "\(projectPath)/main/CMakeLists.txt")
        try mainComponentCMake.write(to: mainComponentURL, atomically: true, encoding: .utf8)
        
        // Generate main/main.swift (ESP-IDF entry point)
        let mainSwiftContent = generateESPIDFMainSwift(projectName: projectName)
        let mainSwiftURL = URL(fileURLWithPath: "\(projectPath)/main/main.swift")
        try mainSwiftContent.write(to: mainSwiftURL, atomically: true, encoding: .utf8)
        
        // Generate main/swift_main.c (C bridge)
        let swiftMainC = generateSwiftMainC()
        let swiftMainCURL = URL(fileURLWithPath: "\(projectPath)/main/swift_main.c")
        try swiftMainC.write(to: swiftMainCURL, atomically: true, encoding: .utf8)
        
        // Generate sdkconfig.defaults
        let sdkConfig = generateSDKConfig(board: board)
        let sdkConfigURL = URL(fileURLWithPath: "\(projectPath)/sdkconfig.defaults")
        try sdkConfig.write(to: sdkConfigURL, atomically: true, encoding: .utf8)
    }
    
    private func generateMainCMakeLists(projectName: String, board: String) -> String {
        let target = getESPIDFTarget(for: board)
        
        return """
        # CMakeLists.txt for ESPHome Swift Embedded project
        # Generated for \(projectName) - Board: \(board)
        cmake_minimum_required(VERSION 3.16)
        
        # Set the target before including project.cmake
        set(IDF_TARGET "\(target)")
        
        include($ENV{IDF_PATH}/tools/cmake/project.cmake)
        project(\(projectName))
        """
    }
    
    private func generateMainComponentCMakeLists() -> String {
        return """
        # Main component CMakeLists.txt
        # This component contains the Swift Embedded code compiled to RISC-V
        
        # Set Swift compilation variables  
        file(GLOB_RECURSE FIRMWARE_SOURCES "../Sources/Firmware/*.swift")
        file(GLOB_RECURSE HARDWARE_SOURCES "../Sources/ESP32Hardware/*.swift")
        set(SWIFT_SOURCES 
            "main.swift"
            \\${FIRMWARE_SOURCES}
            \\${HARDWARE_SOURCES}
        )
        set(SWIFT_TARGET "riscv32-none-none-eabi")
        set(SWIFT_FLAGS
            -target \\${SWIFT_TARGET}
            -Xcc -march=rv32imc_zicsr_zifencei
            -Xcc -mabi=ilp32
            -enable-experimental-feature Embedded
            -DSWIFT_EMBEDDED
            -wmo
            -parse-as-library
            -c
        )
        
        # Create custom command to compile Swift at build time
        add_custom_command(
            OUTPUT main.o
            COMMAND swiftc \\${SWIFT_FLAGS} -o main.o \\${SWIFT_SOURCES}
            DEPENDS \\${SWIFT_SOURCES}
            WORKING_DIRECTORY \\${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Compiling Swift sources to RISC-V object file"
            VERBATIM
        )
        
        # Create custom target for Swift compilation
        add_custom_target(swift_compilation DEPENDS main.o)
        
        # Register the component with C bridge only
        idf_component_register(
            SRCS "swift_main.c"
            INCLUDE_DIRS "."
            REQUIRES "driver" "esp_system" "freertos"
        )
        
        # Add the Swift object file to the component after registration
        target_sources(\\${COMPONENT_LIB} PRIVATE main.o)
        add_dependencies(\\${COMPONENT_LIB} swift_compilation)
        """
    }
    
    private func generateESPIDFMainSwift(projectName: String) -> String {
        return """
        // ESPHome Swift Embedded Firmware - ESP-IDF Entry Point
        // Generated for \(projectName)
        
        @_cdecl("swift_main")
        public func swiftMain() {
            // Import the generated firmware code
            // Note: In Swift Embedded, all Swift files are compiled together
            print("Starting \(projectName) firmware...")
            
            // Initialize the firmware
            do {
                try \(projectName.pascalCased())Firmware.main()
            } catch {
                print("Firmware error: \\(error)")
            }
        }
        """
    }
    
    private func generateSwiftMainC() -> String {
        return """
        // C bridge for Swift Embedded firmware
        // This file provides the ESP-IDF entry point and calls into Swift code
        
        #include <stdio.h>
        #include "freertos/FreeRTOS.h"
        #include "freertos/task.h"
        #include "esp_system.h"
        #include "esp_log.h"
        
        // Swift function declaration
        extern void swift_main(void);
        
        static const char *TAG = "swift_firmware";
        
        void app_main(void) {
            ESP_LOGI(TAG, "Starting Swift Embedded firmware");
            
            // Call into Swift code
            swift_main();
            
            ESP_LOGI(TAG, "Swift firmware completed");
        }
        """
    }
    
    private func generateSDKConfig(board: String) -> String {
        let target = getESPIDFTarget(for: board)
        
        return """
        # ESP-IDF Configuration for \(board)
        # Generated sdkconfig.defaults
        
        # Target configuration
        CONFIG_IDF_TARGET="\(target)"
        
        # Enable ESP32 features needed for Swift Embedded
        CONFIG_FREERTOS_HZ=1000
        CONFIG_ESP_TASK_WDT_TIMEOUT_S=10
        CONFIG_ESP_MAIN_TASK_STACK_SIZE=8192
        
        # Memory configuration for Swift runtime
        CONFIG_SPIRAM=n
        CONFIG_ESP32_SPIRAM_SUPPORT=n
        
        # Enable logging
        CONFIG_LOG_DEFAULT_LEVEL_INFO=y
        CONFIG_LOG_MAXIMUM_LEVEL=5
        
        # Compiler optimizations
        CONFIG_COMPILER_OPTIMIZATION_SIZE=y
        """
    }
    
    private func getESPIDFTarget(for board: String) -> String {
        switch board {
        case "esp32-c3-devkitm-1":
            return "esp32c3"
        case "esp32-c6-devkitc-1":
            return "esp32c6"
        case "esp32-h2-devkitm-1":
            return "esp32h2"
        case "esp32-p4-devkit":
            return "esp32p4"
        default:
            return "esp32c6" // Default to C6
        }
    }
}

/// Generated Swift package information
public struct GeneratedSwiftPackage {
    public let path: String
    public let targetName: String
    public let executableName: String
}

/// Component source file
struct ComponentSource {
    let fileName: String
    let content: String
}

// String extension for camelCase conversion is in ComponentAssembler.swift