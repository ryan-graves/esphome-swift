# Error 001: Swift Embedded Toolchain Requirements

**Date**: July 21, 2025  
**Error**: "module 'Swift' cannot be imported in embedded Swift mode"  
**Impact**: Cannot compile Swift Embedded code  

## Problem Description

When attempting to build Swift Embedded code with the current Swift 6.2 release:
```
error: emit-module command failed with exit code 1
<unknown>:0: error: module 'Swift' cannot be imported in embedded Swift mode
```

This occurs because:
1. Swift Embedded requires experimental features only in development snapshots
2. The release toolchain lacks necessary embedded runtime support
3. Special compiler flags need experimental feature support

## Root Cause

Swift Embedded is still experimental and requires:
- Development snapshot toolchain (main branch)
- `-enable-experimental-feature Embedded` flag
- Special compilation settings for microcontrollers
- Modified standard library for embedded use

## Solution

### Step 1: Install Swift Development Snapshot

#### macOS
1. Visit https://swift.org/download/#snapshots
2. Download latest "Trunk Development (main)" snapshot
3. Install the .pkg file
4. Select toolchain in Xcode or use CLI

#### Linux
1. Download appropriate snapshot for your distribution
2. Extract to `/opt/swift-dev`
3. Update PATH to use development toolchain

### Step 2: Verify Installation
```bash
# Check version - should show "dev" or "main"
swift --version

# Test Embedded feature
echo '@main struct Test { static func main() {} }' > test.swift
swift -frontend -c test.swift -enable-experimental-feature Embedded
```

### Step 3: Configure Build Environment

#### For Package.swift
```swift
.executableTarget(
    name: "ESP32Firmware",
    swiftSettings: [
        .enableExperimentalFeature("Embedded"),
        .unsafeFlags([
            "-Xfrontend", "-function-sections",
            "-Xfrontend", "-data-sections"
        ])
    ]
)
```

#### For Command Line
```bash
swift build -c release \
    -Xswiftc -enable-experimental-feature \
    -Xswiftc Embedded \
    -Xswiftc -target -Xswiftc riscv32-none-none-eabi
```

## Workaround (If Cannot Install Snapshot)

While we cannot compile actual Swift Embedded binaries without the snapshot, we can:

1. **Design and document** the Swift Embedded architecture
2. **Create component implementations** that will compile once toolchain is available
3. **Test logic** using regular Swift with mocked hardware interfaces
4. **Prepare migration** by identifying all C++ generation points

## Verification Steps

Once development snapshot is installed:

1. Create minimal embedded test:
```swift
@main
struct MinimalTest {
    static func main() {
        // Minimal embedded program
    }
}
```

2. Compile for embedded target:
```bash
swiftc -frontend -c minimal.swift \
    -enable-experimental-feature Embedded \
    -target riscv32-none-none-eabi
```

3. Success indicators:
- No import errors
- Creates .o file
- No runtime dependencies

## Impact on Migration

**Without development snapshot**:
- Cannot compile actual ESP32 binaries
- Cannot test on hardware
- Can still design architecture
- Can still implement components

**With development snapshot**:
- Full compilation to ESP32
- Hardware testing possible
- Binary size validation
- Performance benchmarking

## Next Steps

1. **Priority**: Install development snapshot on build machine
2. **Alternative**: Use CI/CD with snapshot pre-installed
3. **Continue**: Architecture design and component implementation
4. **Document**: All toolchain-specific requirements

## References

- Swift.org Downloads: https://swift.org/download/
- Embedded Swift Guide: https://swift.org/getting-started/embedded-swift/
- ESP32 Swift Examples: https://github.com/apple/swift-embedded-examples