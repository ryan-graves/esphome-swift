import Foundation
import ESPHomeSwiftCore

/// Component Library - Built-in component definitions and factories
///
/// This module provides concrete implementations of ESPHome Swift components,
/// including sensors, actuators, networking components, and their code generation
/// templates.

/// Component registry for managing available components
public final class ComponentRegistry {
    public static let shared = ComponentRegistry()
    
    private var componentFactories: [String: AnyComponentFactory] = [:]
    
    private init() {
        registerBuiltInComponents()
    }
    
    /// Register a component factory
    public func register<T: ComponentFactory>(_ factory: T) {
        componentFactories[factory.platform] = AnyComponentFactory(factory)
    }
    
    /// Get component factory for platform
    public func factory(for platform: String) -> AnyComponentFactory? {
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

/// Type-safe protocol for component factories
public protocol ComponentFactory {
    /// Associated type that defines the specific configuration this factory accepts
    associatedtype ConfigType: ComponentConfig
    
    /// Platform identifier (e.g., "dht", "gpio")
    var platform: String { get }
    
    /// Component type classification
    var componentType: ComponentType { get }
    
    /// Required configuration properties
    var requiredProperties: [String] { get }
    
    /// Optional configuration properties  
    var optionalProperties: [String] { get }
    
    /// Validate configuration with compile-time type safety
    func validate(config: ConfigType) throws
    
    /// Generate code with compile-time type safety
    func generateCode(config: ConfigType, context: CodeGenerationContext) throws -> ComponentCode
}

/// Type-erased wrapper for ComponentFactory storage in collections
public struct AnyComponentFactory {
    public let platform: String
    public let componentType: ComponentType
    public let requiredProperties: [String]
    public let optionalProperties: [String]
    
    private let _validate: (ComponentConfig) throws -> Void
    private let _generateCode: (ComponentConfig, CodeGenerationContext) throws -> ComponentCode
    
    /// Initialize with a type-safe factory
    public init<T: ComponentFactory>(_ factory: T) {
        // Store properties
        self.platform = factory.platform
        self.componentType = factory.componentType
        self.requiredProperties = factory.requiredProperties
        self.optionalProperties = factory.optionalProperties
        
        // Create type-safe closures
        self._validate = { config in
            guard let typedConfig = config as? T.ConfigType else {
                throw ComponentValidationError.incompatibleConfiguration(
                    component: factory.platform,
                    reason: "Expected \(T.ConfigType.self) but got \(type(of: config))"
                )
            }
            try factory.validate(config: typedConfig)
        }
        
        self._generateCode = { config, context in
            guard let typedConfig = config as? T.ConfigType else {
                throw ComponentValidationError.incompatibleConfiguration(
                    component: factory.platform,
                    reason: "Expected \(T.ConfigType.self) but got \(type(of: config))"
                )
            }
            return try factory.generateCode(config: typedConfig, context: context)
        }
    }
    
    public func validate(config: ComponentConfig) throws {
        try _validate(config)
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        return try _generateCode(config, context)
    }
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