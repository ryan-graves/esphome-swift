import Foundation
import ESPHomeSwiftCore

/// Component Library - Built-in component definitions and factories
///
/// This module provides concrete implementations of ESPHome Swift components,
/// including sensors, actuators, networking components, and their code generation
/// templates.

/// Component registry for managing available components
public final class ComponentRegistry: @unchecked Sendable {
    public static let shared = ComponentRegistry()
    
    private var componentFactories: [String: ComponentFactory] = [:]
    
    private init() {
        registerBuiltInComponents()
    }
    
    /// Register a component factory
    public func register<T: ComponentFactory>(_ factory: T) {
        componentFactories[factory.platform] = factory
    }
    
    /// Get component factory for platform
    public func factory(for platform: String) -> ComponentFactory? {
        return componentFactories[platform]
    }
    
    /// List all available platforms
    public var availablePlatforms: [String] {
        return Array(componentFactories.keys).sorted()
    }
    
    /// Register built-in components
    private func registerBuiltInComponents() {
        // Sensor components
        register(DHTSensorFactory())
        register(GPIOSensorFactory())
        
        // Switch components
        register(GPIOSwitchFactory())
        
        // Light components
        register(BinaryLightFactory())
        register(RGBLightFactory())
        
        // Binary sensor components
        register(GPIOBinarySensorFactory())
    }
}

/// Base protocol for component factories
public protocol ComponentFactory {
    var platform: String { get }
    var componentType: ComponentType { get }
    var requiredProperties: [String] { get }
    var optionalProperties: [String] { get }
    
    func validate(config: ComponentConfig) throws
    func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode
}

/// Component types
public enum ComponentType: String, CaseIterable {
    case sensor
    case switch_
    case light
    case binarySensor = "binary_sensor"
    case climate
    case cover
    case fan
    case lock
    case mediaPlayer = "media_player"
    case number
    case select
    case text
    case textSensor = "text_sensor"
}

/// Generated component code
public struct ComponentCode {
    public let headerIncludes: [String]
    public let globalDeclarations: [String]
    public let setupCode: [String]
    public let loopCode: [String]
    public let classDefinitions: [String]
    
    public init(
        headerIncludes: [String] = [],
        globalDeclarations: [String] = [],
        setupCode: [String] = [],
        loopCode: [String] = [],
        classDefinitions: [String] = []
    ) {
        self.headerIncludes = headerIncludes
        self.globalDeclarations = globalDeclarations
        self.setupCode = setupCode
        self.loopCode = loopCode
        self.classDefinitions = classDefinitions
    }
}

/// Code generation context
public struct CodeGenerationContext {
    public let configuration: ESPHomeConfiguration
    public let outputDirectory: String
    public let targetBoard: String
    public let framework: FrameworkType
    
    public init(
        configuration: ESPHomeConfiguration,
        outputDirectory: String,
        targetBoard: String,
        framework: FrameworkType
    ) {
        self.configuration = configuration
        self.outputDirectory = outputDirectory
        self.targetBoard = targetBoard
        self.framework = framework
    }
}

/// Component validation errors
public enum ComponentValidationError: Error, LocalizedError {
    case missingRequiredProperty(component: String, property: String)
    case invalidPropertyValue(component: String, property: String, value: String, reason: String)
    case incompatibleConfiguration(component: String, reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .missingRequiredProperty(let component, let property):
            return "Missing required property '\(property)' in \(component) component"
        case .invalidPropertyValue(let component, let property, let value, let reason):
            return "Invalid value '\(value)' for property '\(property)' in \(component) component: \(reason)"
        case .incompatibleConfiguration(let component, let reason):
            return "Incompatible configuration for \(component) component: \(reason)"
        }
    }
}