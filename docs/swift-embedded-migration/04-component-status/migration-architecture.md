# Swift Embedded Migration Architecture

**Last Updated**: July 21, 2025  
**Purpose**: Define how ESPHome Swift transitions from C++ generation to Swift Embedded

## Current Architecture (C++ Generation)

```
YAML Config → Swift Parser → ComponentFactory → C++ Code String → ESP-IDF Build
```

### Example: Current DHT Implementation
```swift
// Current: Generates C++ code strings
func generateCode() -> ComponentCode {
    return ComponentCode(
        headerIncludes: ["#include \"DHT.h\""],
        globalDeclarations: ["DHT dht_sensor(4, DHT22);"],
        setupCode: ["dht_sensor.begin();"],
        loopCode: ["float temp = dht_sensor.readTemperature();"]
    )
}
```

**Problem**: Arduino library dependency (`DHT.h`) not available in ESP-IDF

## Target Architecture (Swift Embedded)

```
YAML Config → Swift Parser → Swift Component Assembly → Swift Embedded Build → ESP32 Firmware
```

### Example: Swift Embedded DHT Implementation
```swift
// Target: Native Swift component
struct DHTSensor: Component {
    let pin: GPIO
    let model: DHTModel
    
    func setup() throws {
        try pin.setDirection(.inputPullUp)
        // Native DHT protocol implementation
    }
    
    func readTemperature() -> Float? {
        // Direct hardware communication
    }
}
```

**Solution**: No external library dependencies, pure Swift implementation

## Migration Components

### 1. Build System Changes

#### Current: ProjectBuilder.swift
- Generates ESP-IDF project structure
- Creates CMakeLists.txt
- Writes C++ main.cpp
- Calls ESP-IDF build tools

#### Target: SwiftEmbeddedBuilder.swift
- Generates Swift Package structure
- Creates Package.swift with Embedded settings
- Assembles Swift components
- Calls Swift compiler with embedded flags

### 2. Code Generation Changes

#### Current: CodeGenerator.swift
```swift
// Generates C++ code strings
func generateMainCpp() -> String {
    var cpp = "#include <stdio.h>\\n"
    // ... string concatenation
    return cpp
}
```

#### Target: SwiftEmbeddedAssembler.swift
```swift
// Assembles Swift components
func assembleComponents(config: ESPHomeConfiguration) -> [any Component] {
    var components: [any Component] = []
    
    // Create component instances from config
    for sensor in config.sensor {
        let component = componentFactory.create(from: sensor)
        components.append(component)
    }
    
    return components
}
```

### 3. Component Factory Evolution

#### Current Pattern
```swift
protocol ComponentFactory {
    func generateCode(config: ComponentConfig) -> ComponentCode
}
```

#### Swift Embedded Pattern
```swift
protocol SwiftEmbeddedComponentFactory {
    associatedtype ComponentType: Component
    func createComponent(config: ComponentConfig) -> ComponentType
}
```

### 4. Hardware Abstraction Layer

#### New Modules Needed
1. **ESP32Hardware**
   - GPIO control
   - I2C/SPI communication
   - ADC/PWM interfaces
   - WiFi management

2. **SwiftEmbeddedCore**
   - Component protocols
   - Event system
   - State management
   - Error handling

## Component Migration Priority

### Phase 1: Foundation Components
1. **GPIO Switch** - Simplest component, digital I/O only
2. **GPIO Binary Sensor** - Input with state reporting
3. **ADC Sensor** - Analog input, introduces voltage calculations

### Phase 2: Communication Components  
1. **DHT Sensor** - Custom protocol, tutorial blocker
2. **I2C Sensors** - BME280, common pattern
3. **SPI Components** - More complex communication

### Phase 3: Advanced Components
1. **RGB Light** - PWM control, multiple channels
2. **Addressable LEDs** - Timing-critical protocols
3. **WiFi/API** - Network stack integration

## File Structure Evolution

### Current Structure
```
Sources/
├── CodeGeneration/
│   ├── CodeGenerator.swift      # C++ string generation
│   └── ProjectBuilder.swift     # ESP-IDF project creation
└── ComponentLibrary/
    └── Sensors/
        └── DHTSensor.swift      # Generates C++ code
```

### Target Structure
```
Sources/
├── SwiftEmbeddedGen/
│   ├── ComponentAssembler.swift # Swift component assembly
│   └── FirmwareBuilder.swift    # Swift Embedded compilation
├── ESP32Hardware/               # NEW: Hardware abstraction
│   ├── GPIO.swift
│   ├── I2C.swift
│   └── WiFi.swift
├── SwiftEmbeddedCore/          # NEW: Core protocols
│   ├── Component.swift
│   └── EventLoop.swift
└── ComponentLibrary/
    └── Sensors/
        └── DHTSensor.swift      # Swift component implementation
```

## CLI Command Evolution

### Current Commands
- `build` - Generates C++ code, calls ESP-IDF
- `flash` - Uses ESP-IDF flash tools
- `validate` - Checks YAML configuration

### Additional Commands Needed
- `build --embedded` - Swift Embedded compilation mode
- `test-component` - Hardware component testing
- `generate-hal` - Create hardware abstraction stubs

## Testing Strategy

### Unit Testing
- Mock hardware interfaces for component logic
- Test YAML to Swift component mapping
- Validate error handling paths

### Integration Testing
```swift
// Test harness for hardware validation
class ComponentTestHarness {
    func testDHTSensor() async throws {
        let sensor = DHTSensor(pin: .pin4, model: .dht22)
        try sensor.setup()
        
        // Read multiple times to ensure stability
        for _ in 0..<10 {
            if let temp = try sensor.readTemperature() {
                XCTAssertGreaterThan(temp, -40)
                XCTAssertLessThan(temp, 80)
            }
        }
    }
}
```

### Hardware Testing Requirements
- ESP32-C6 development board
- Test components (DHT22, LEDs, etc.)
- Automated test runner on actual hardware

## Success Metrics

### Technical Metrics
- [ ] Zero Arduino library dependencies
- [ ] All components compile with Swift Embedded
- [ ] Binary size comparable to C++ generation
- [ ] Performance within 10% of C++ version

### User Experience Metrics
- [ ] Same YAML syntax works unchanged
- [ ] Better error messages from Swift compiler
- [ ] Faster development cycle (no C++ compilation)
- [ ] Tutorial completes successfully

## Risk Mitigation

### Technical Risks
1. **Swift Embedded limitations** 
   - Mitigation: Start with simple components, validate capabilities early
   
2. **Performance concerns**
   - Mitigation: Benchmark each component, optimize critical paths
   
3. **Binary size growth**
   - Mitigation: Use size optimization flags, monitor continuously

### Migration Risks
1. **Component compatibility**
   - Mitigation: Maintain parallel implementations during transition
   
2. **Testing coverage**
   - Mitigation: Automated hardware testing from day one
   
3. **Documentation lag**
   - Mitigation: Update docs with each component migration

## Next Steps

1. **Install Swift development snapshot** on build environment
2. **Create minimal ESP32 Swift Embedded project** that compiles
3. **Implement GPIO component** as proof of concept
4. **Design component factory pattern** for Swift Embedded
5. **Begin systematic component migration** following priority list