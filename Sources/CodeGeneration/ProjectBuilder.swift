import Foundation
import ESPHomeSwiftCore
import SystemPackage
import Logging

/// Project builder for ESP-IDF integration
public class ProjectBuilder {
    private let logger = Logger(label: "ProjectBuilder")
    
    public init() {}
    
    /// Build project using ESP-IDF
    public func buildProject(
        generatedProject: GeneratedProject,
        configuration: ESPHomeConfiguration,
        outputDirectory: String
    ) throws -> BuildResult {
        logger.info("Building project: \(configuration.esphomeSwift.name)")
        
        let projectPath = "\(outputDirectory)/\(configuration.esphomeSwift.name)"
        
        // Create project directory structure
        try createProjectStructure(projectPath: projectPath)
        
        // Write generated files
        try writeProjectFiles(
            generatedProject: generatedProject,
            projectPath: projectPath
        )
        
        // Configure ESP-IDF
        try configureESPIDF(
            configuration: configuration,
            projectPath: projectPath
        )
        
        // Build the project
        let buildOutput = try runESPIDFBuild(projectPath: projectPath)
        
        logger.info("Build completed successfully")
        
        return BuildResult(
            projectPath: projectPath,
            firmwarePath: "\(projectPath)/build/\(configuration.esphomeSwift.name).bin",
            buildOutput: buildOutput,
            success: true
        )
    }
    
    /// Flash firmware to device
    public func flashProject(
        buildResult: BuildResult,
        port: String? = nil,
        baudRate: Int = 460800
    ) throws -> FlashResult {
        logger.info("Flashing firmware to device")
        
        let flashCommand = buildFlashCommand(
            projectPath: buildResult.projectPath,
            port: port,
            baudRate: baudRate
        )
        
        let flashOutput = try runCommand(flashCommand, workingDirectory: buildResult.projectPath)
        
        logger.info("Flash completed successfully")
        
        return FlashResult(
            output: flashOutput,
            success: true
        )
    }
    
    /// Monitor serial output
    public func monitorSerial(
        buildResult: BuildResult,
        port: String? = nil,
        baudRate: Int = 115200
    ) throws {
        logger.info("Starting serial monitor")
        
        let monitorCommand = buildMonitorCommand(
            projectPath: buildResult.projectPath,
            port: port,
            baudRate: baudRate
        )
        
        // This would run in a separate process for continuous monitoring
        _ = try runCommand(monitorCommand, workingDirectory: buildResult.projectPath)
    }
    
    // MARK: - Private Methods
    
    /// Create ESP-IDF project directory structure
    private func createProjectStructure(projectPath: String) throws {
        let directories = [
            projectPath,
            "\(projectPath)/main",
            "\(projectPath)/components",
            "\(projectPath)/build"
        ]
        
        for directory in directories {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    /// Write generated project files
    private func writeProjectFiles(
        generatedProject: GeneratedProject,
        projectPath: String
    ) throws {
        // Write main.cpp
        let mainCppPath = "\(projectPath)/main/main.cpp"
        try generatedProject.mainCpp.write(
            toFile: mainCppPath,
            atomically: true,
            encoding: .utf8
        )
        
        // Write CMakeLists.txt for main component
        let mainCMakePath = "\(projectPath)/main/CMakeLists.txt"
        let mainCMakeContent = """
        idf_component_register(SRCS "main.cpp"
                              INCLUDE_DIRS "."
                              REQUIRES driver nvs_flash esp_wifi esp_event esp_netif)
        """
        try mainCMakeContent.write(
            toFile: mainCMakePath,
            atomically: true,
            encoding: .utf8
        )
        
        // Write root CMakeLists.txt
        let rootCMakePath = "\(projectPath)/CMakeLists.txt"
        try generatedProject.cmakeLists.write(
            toFile: rootCMakePath,
            atomically: true,
            encoding: .utf8
        )
        
        // Write sdkconfig
        let sdkConfigPath = "\(projectPath)/sdkconfig"
        try generatedProject.sdkConfig.write(
            toFile: sdkConfigPath,
            atomically: true,
            encoding: .utf8
        )
    }
    
    /// Configure ESP-IDF for the target
    private func configureESPIDF(
        configuration: ESPHomeConfiguration,
        projectPath: String
    ) throws {
        // Set target board
        let setTargetCommand = ["idf.py", "set-target", extractESPIDFTarget(configuration.esp32.board)]
        _ = try runCommand(setTargetCommand, workingDirectory: projectPath)
        
        // Configure project
        let configCommand = ["idf.py", "reconfigure"]
        _ = try runCommand(configCommand, workingDirectory: projectPath)
    }
    
    /// Run ESP-IDF build
    private func runESPIDFBuild(projectPath: String) throws -> String {
        let buildCommand = ["idf.py", "build"]
        return try runCommand(buildCommand, workingDirectory: projectPath)
    }
    
    /// Build flash command
    private func buildFlashCommand(
        projectPath: String,
        port: String?,
        baudRate: Int
    ) -> [String] {
        var command = ["idf.py", "flash", "-b", String(baudRate)]
        
        if let port = port {
            command.append(contentsOf: ["-p", port])
        }
        
        return command
    }
    
    /// Build monitor command
    private func buildMonitorCommand(
        projectPath: String,
        port: String?,
        baudRate: Int
    ) -> [String] {
        var command = ["idf.py", "monitor", "-b", String(baudRate)]
        
        if let port = port {
            command.append(contentsOf: ["-p", port])
        }
        
        return command
    }
    
    /// Extract ESP-IDF target from board name
    private func extractESPIDFTarget(_ board: String) -> String {
        // Map board names to ESP-IDF targets
        let targetMap: [String: String] = [
            "esp32-c3-devkitm-1": "esp32c3",
            "esp32-c3-devkitc-02": "esp32c3",
            "esp32-c6-devkitc-1": "esp32c6",
            "esp32-h2-devkitm-1": "esp32h2",
            "esp32-p4-function-ev-board": "esp32p4"
        ]
        
        return targetMap[board] ?? "esp32c6" // Default to C6
    }
    
    /// Run shell command
    private func runCommand(
        _ command: [String],
        workingDirectory: String
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = command
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        guard process.terminationStatus == 0 else {
            throw BuildError.commandFailed(command: command.joined(separator: " "), output: output)
        }
        
        return output
    }
}

/// Build result
public struct BuildResult {
    public let projectPath: String
    public let firmwarePath: String
    public let buildOutput: String
    public let success: Bool
    
    public init(projectPath: String, firmwarePath: String, buildOutput: String, success: Bool) {
        self.projectPath = projectPath
        self.firmwarePath = firmwarePath
        self.buildOutput = buildOutput
        self.success = success
    }
}

/// Flash result
public struct FlashResult {
    public let output: String
    public let success: Bool
    
    public init(output: String, success: Bool) {
        self.output = output
        self.success = success
    }
}

/// Build errors
public enum BuildError: Error, LocalizedError {
    case commandFailed(command: String, output: String)
    case espIDFNotFound
    case invalidBoard(String)
    case buildFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let output):
            return "Command failed: \(command)\nOutput: \(output)"
        case .espIDFNotFound:
            return "ESP-IDF not found. Please install and source ESP-IDF v5.3+"
        case .invalidBoard(let board):
            return "Invalid board: \(board)"
        case .buildFailed(let message):
            return "Build failed: \(message)"
        }
    }
}