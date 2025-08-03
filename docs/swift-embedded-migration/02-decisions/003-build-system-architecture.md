# Decision 003: Build System Architecture for Swift Embedded

**Date**: July 21, 2025  
**Status**: Implemented  
**Decision Maker**: Architecture analysis  

## Context

ESPHome Swift currently uses a multi-stage build process:
1. Parse YAML configuration
2. Generate C++ code strings
3. Create ESP-IDF project structure
4. Call ESP-IDF build tools
5. Flash resulting binary

For Swift Embedded, we need a fundamentally different approach:
1. Parse YAML configuration
2. Generate Swift component assembly
3. Compile with Swift Embedded toolchain
4. Link with ESP32 runtime
5. Flash resulting binary

## Decision

**Implement dual-mode build system** supporting both C++ generation (current) and Swift Embedded (new):

### Build Mode Selection
```yaml
esp32:
  board: esp32-c6-devkitc-1
  framework:
    type: swift-embedded  # New option alongside 'esp-idf'
```

### Architecture Components

#### 1. SwiftEmbeddedBuilder (New)
Replaces ProjectBuilder for Swift mode:
- Generates Swift Package structure
- Assembles components into main.swift
- Invokes Swift compiler with embedded flags
- Links with ESP32 runtime libraries

#### 2. ComponentAssembler (New)
Replaces CodeGenerator for Swift mode:
- Creates Swift component instances from YAML
- Generates component initialization code
- Handles dependency injection
- Produces compilable Swift source

#### 3. Unified CLI Interface
Maintains same user experience:
- `esphome-swift build` works for both modes
- Framework type determines build path
- Same validation and error reporting

## Implementation Plan

### Phase 1: Parallel Architecture
Keep existing C++ path while adding Swift:
```
CLI.swift
├── BuildCommand
│   ├── detectFramework() → FrameworkType
│   ├── buildWithCpp() → existing path
│   └── buildWithSwiftEmbedded() → new path
```

### Phase 2: Swift Build Pipeline

#### SwiftPackageGenerator
```swift
struct SwiftPackageGenerator {
    func generatePackage(config: ESPHomeConfiguration) -> GeneratedPackage {
        // Create Package.swift
        let package = createPackageManifest(config)
        
        // Generate main.swift
        let mainSwift = assembleMainFile(config)
        
        // Copy component implementations
        let components = copyComponentSources(config)
        
        return GeneratedPackage(
            packageSwift: package,
            mainSwift: mainSwift,
            componentSources: components
        )
    }
}
```

#### Component Assembly Pattern
```swift
// Generated main.swift structure
import ESP32Hardware
import SwiftEmbeddedCore

@main
struct GeneratedFirmware {
    static var components: [any Component] = []
    
    static func main() {
        // Initialize hardware
        initializeSystem()
        
        // Create components from YAML
        components = [
            createDHTSensor(),
            createGPIOSwitch(),
            createRGBLight()
        ]
        
        // Setup all components
        setupComponents()
        
        // Main event loop
        runEventLoop()
    }
}
```

### Phase 3: Build Execution

#### Swift Compilation Command
```swift
struct SwiftEmbeddedCompiler {
    func compile(package: GeneratedPackage, target: String) throws -> Binary {
        let buildDir = package.path + "/.build"
        
        // Swift build command for embedded
        let command = [
            "swift", "build",
            "-c", "release",
            "--triple", targetTriple(for: target),
            "-Xswiftc", "-enable-experimental-feature",
            "-Xswiftc", "Embedded",
            "-Xswiftc", "-wmo",  // Whole module optimization
            "-Xswiftc", "-O",    // Optimize for size
            "-Xcc", "-I\(esp32Headers)",
            "-Xlinker", "-T\(linkerScript)"
        ]
        
        let output = try runCommand(command)
        
        return extractBinary(from: buildDir)
    }
}
```

### Phase 4: ESP32 Integration

#### Linker Script Generation
- Create ESP32-specific linker scripts
- Map Swift binary to ESP32 memory layout
- Include bootloader and partition table

#### Runtime Library
- Minimal Swift runtime for embedded
- ESP32 startup code integration
- Interrupt handler registration

## Technical Considerations

### Binary Size Optimization
```swift
// Compiler flags for size
swiftSettings: [
    .unsafeFlags([
        "-Xfrontend", "-function-sections",
        "-Xfrontend", "-data-sections",
        "-Xfrontend", "-disable-reflection-metadata",
        "-Xfrontend", "-disable-stack-protector"
    ])
]
```

### Cross-Platform Support
- macOS: Native Swift toolchain support
- Linux: Ensure Swift Embedded works identically
- CI/CD: Docker images with development snapshots

### Incremental Migration
1. Start with simple components (GPIO, ADC)
2. Add complex components progressively
3. Maintain C++ path during transition
4. Deprecate C++ after Swift stability

## Success Criteria

### Technical Success
- [ ] Swift Embedded binaries compile successfully
- [ ] Binary size comparable to C++ output
- [ ] Cross-platform builds work identically
- [ ] Flash and monitor tools work with Swift binaries

### User Experience Success
- [ ] Same CLI commands work transparently
- [ ] Clear error messages from Swift compiler
- [ ] Faster build times than C++ path
- [ ] Seamless transition for existing configs

## Risks & Mitigation

### Risk: Swift Embedded Toolchain Instability
- **Mitigation**: Pin specific snapshot versions
- **Fallback**: Keep C++ path as backup

### Risk: Binary Size Growth
- **Mitigation**: Aggressive optimization flags
- **Monitoring**: Track size for each component

### Risk: Cross-Platform Issues
- **Mitigation**: Extensive CI testing
- **Solution**: Docker-based builds

### Risk: Debugging Complexity
- **Mitigation**: Enhanced logging in Swift mode
- **Tools**: Serial monitor improvements

## Decision Outcome

Proceed with dual-mode build system that:
1. Preserves existing C++ functionality
2. Adds Swift Embedded as opt-in feature
3. Maintains unified user experience
4. Enables gradual migration

**Implementation Status** (July 21, 2025):
1. ✅ Implemented SwiftPackageGenerator in `Sources/SwiftEmbeddedGen/SwiftPackageGenerator.swift`
2. ✅ Created ComponentAssembler in `Sources/SwiftEmbeddedGen/ComponentAssembler.swift`
3. ✅ Added SwiftEmbeddedGen module to Package.swift
4. ✅ Created example configuration in `Examples/swift-embedded-test.yaml`

**Key Implementation Details**:
- SwiftPackageGenerator creates complete Swift package structure with embedded settings
- ComponentAssembler transforms YAML config into Swift component instantiations
- Supports sensors (DHT, ADC, Dallas), switches (GPIO), lights (RGB, monochromatic), and binary sensors
- Generates type-safe main.swift with proper component lifecycle management
- Includes WiFi, API, and OTA support in generated code

**Next Steps**:
1. Add framework detection to CLI BuildCommand
2. Test with physical ESP32-C6 hardware (requires development snapshot)
3. Implement cross-platform build verification
4. Add integration tests for build pipeline