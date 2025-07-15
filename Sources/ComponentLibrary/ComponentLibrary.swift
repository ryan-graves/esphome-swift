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
    
    private var componentFactories: [String: any ComponentFactory] = [:]
    
    private init() {
        registerBuiltInComponents()
    }
    
    /// Register a component factory
    public func register<T: ComponentFactory>(_ factory: T) {
        let key = "\(factory.componentType.rawValue).\(factory.platform)"
        componentFactories[key] = factory
    }
    
    /// Get component factory for platform and component type
    public func factory(for platform: String, componentType: ComponentType) -> (any ComponentFactory)? {
        let key = "\(componentType.rawValue).\(platform)"
        return componentFactories[key]
    }
    
    /// List all available platforms
    public var availablePlatforms: [String] {
        let platforms = componentFactories.keys.compactMap { key in
            key.split(separator: ".").last.map(String.init)
        }
        return Array(Set(platforms)).sorted()
    }
    
    /// Get available platforms for a specific component type
    public func platforms(for componentType: ComponentType) -> [String] {
        let prefix = "\(componentType.rawValue)."
        return componentFactories.keys
            .filter { $0.hasPrefix(prefix) }
            .compactMap { $0.split(separator: ".").last.map(String.init) }
            .sorted()
    }
    
    /// Get all registered factories for enumeration
    public var allFactories: [FactoryInfo] {
        return componentFactories.map { key, factory in
            let parts = key.split(separator: ".")
            let componentTypeString = String(parts[0])
            let platform = String(parts[1])
            let componentType = ComponentType(rawValue: componentTypeString) ?? .sensor
            return FactoryInfo(platform: platform, componentType: componentType, factory: factory)
        }.sorted { $0.platform < $1.platform }
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

/// Factory information for enumeration
public struct FactoryInfo {
    public let platform: String
    public let componentType: ComponentType
    public let factory: any ComponentFactory
    
    public init(platform: String, componentType: ComponentType, factory: any ComponentFactory) {
        self.platform = platform
        self.componentType = componentType
        self.factory = factory
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
    
    /// Validate configuration with board-specific constraints
    func validate(config: ConfigType, board: String) throws
    
    /// Generate code with compile-time type safety
    func generateCode(config: ConfigType, context: CodeGenerationContext) throws -> ComponentCode
    
    /// Type-erased board-aware validate method for dynamic dispatch
    func validateAny(config: ComponentConfig, board: String) throws
    
    /// Type-erased generateCode method for dynamic dispatch  
    func generateCodeAny(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode
}

/// Default implementations for shared helper methods
public extension ComponentFactory {
    
    // MARK: - Shared Board Validation Helpers
    
    /// Create a board-specific pin validator
    /// - Parameters:
    ///   - board: Board identifier
    /// - Returns: PinValidator configured for the specified board
    /// - Throws: ComponentValidationError if board is unsupported
    func createPinValidator(for board: String) throws -> PinValidator {
        guard let boardDef = BoardCapabilities.boardDefinition(for: board) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "board",
                value: board,
                reason: "Unsupported board. Use 'swift run esphome-swift boards' to see available boards."
            )
        }
        return PinValidator(boardConstraints: boardDef.pinConstraints)
    }
    
    /// Get board definition for code generation context
    /// - Parameters:
    ///   - context: Code generation context containing target board
    /// - Returns: Board definition for the target board
    /// - Throws: ComponentValidationError if board is unsupported
    func getBoardDefinition(from context: CodeGenerationContext) throws -> BoardCapabilities.BoardDefinition {
        guard let boardDef = BoardCapabilities.boardDefinition(for: context.targetBoard) else {
            throw ComponentValidationError.invalidPropertyValue(
                component: platform,
                property: "board",
                value: context.targetBoard,
                reason: "Unsupported board"
            )
        }
        return boardDef
    }
    
    func validateAny(config: ComponentConfig, board: String) throws {
        guard let typedConfig = config as? ConfigType else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected \(ConfigType.self) but got \(type(of: config))"
            )
        }
        try validate(config: typedConfig, board: board)
    }
    
    func generateCodeAny(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        guard let typedConfig = config as? ConfigType else {
            throw ComponentValidationError.incompatibleConfiguration(
                component: platform,
                reason: "Expected \(ConfigType.self) but got \(type(of: config))"
            )
        }
        return try generateCode(config: typedConfig, context: context)
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