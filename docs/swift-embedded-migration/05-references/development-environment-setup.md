# Swift Embedded Development Environment Setup

**Last Updated**: July 20, 2025  
**Purpose**: Complete guide for setting up Swift Embedded development for ESP32 boards

## Prerequisites

### Hardware Requirements
- ESP32-C6, ESP32-C3, ESP32-H2, or ESP32-P4 development board (RISC-V architecture)
- USB-C cable for programming and power
- Breadboard and jumper wires for component testing
- Sensors/components for testing (DHT22, LEDs, etc.)

### Software Requirements
- macOS 12.0+ or Linux (Ubuntu 20.04+ recommended)
- Git for source code management
- USB drivers for ESP32 boards (usually automatic)

## Swift Embedded Toolchain Installation

### macOS Installation

#### Step 1: Download Development Snapshot
```bash
# Go to https://swift.org/install/
# Download "Development Snapshot" (NOT release version)
# Swift Embedded requires preview toolchain

# Example for current snapshot (URL changes frequently):
curl -O https://download.swift.org/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a/swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a-osx.pkg
```

#### Step 2: Install Toolchain
```bash
# Install the downloaded package
sudo installer -pkg swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a-osx.pkg -target /

# Verify installation
swift --version
# Should show development snapshot version
```

#### Step 3: Xcode Integration (Optional)
```bash
# If using Xcode, select the development toolchain:
# Xcode > Preferences > Components > Toolchains
# Select the development snapshot
```

### Linux Installation

#### Step 1: Install Dependencies
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-9-dev \
    libpython3.8 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev
```

#### Step 2: Download and Install Swift
```bash
# Download development snapshot
curl -O https://download.swift.org/development/ubuntu2004/swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a/swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a-ubuntu20.04.tar.gz

# Extract
tar xzf swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a-ubuntu20.04.tar.gz

# Move to standard location
sudo mv swift-DEVELOPMENT-SNAPSHOT-2025-07-XX-a-ubuntu20.04 /opt/swift

# Add to PATH
echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify installation
swift --version
```

## ESP-IDF Installation

### macOS ESP-IDF Setup
```bash
# Install ESP-IDF prerequisites
brew install cmake ninja dfu-util

# Clone ESP-IDF
mkdir -p ~/esp
cd ~/esp
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git checkout v5.3

# Install ESP-IDF
./install.sh esp32c6

# Set up environment
echo 'alias get_idf=". $HOME/esp/esp-idf/export.sh"' >> ~/.zshrc
source ~/.zshrc

# Activate ESP-IDF environment
get_idf
```

### Linux ESP-IDF Setup
```bash
# Install ESP-IDF prerequisites
sudo apt install -y git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# Clone ESP-IDF
mkdir -p ~/esp
cd ~/esp
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git checkout v5.3

# Install ESP-IDF
./install.sh esp32c6

# Set up environment
echo 'alias get_idf=". $HOME/esp/esp-idf/export.sh"' >> ~/.bashrc
source ~/.bashrc

# Activate ESP-IDF environment
get_idf
```

## Swift Embedded Project Setup

### Creating a Basic Project
```bash
# Create project directory
mkdir SwiftEmbeddedTest
cd SwiftEmbeddedTest

# Create Package.swift
cat > Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftEmbeddedTest",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SwiftEmbeddedTest", targets: ["SwiftEmbeddedTest"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftEmbeddedTest",
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-Xfrontend", "-function-sections",
                    "-Xfrontend", "-data-sections",
                ])
            ]
        )
    ]
)
EOF

# Create source directory
mkdir -p Sources/SwiftEmbeddedTest

# Create main.swift
cat > Sources/SwiftEmbeddedTest/main.swift << 'EOF'
@main
struct Main {
    static func main() {
        print("Hello from Swift Embedded!")
        
        while true {
            // Main application loop
            sleep(1)
        }
    }
}

func sleep(_ seconds: UInt32) {
    // Platform-specific sleep implementation needed
}
EOF
```

### Building for ESP32
```bash
# Set target for ESP32-C6 (RISC-V)
swift build -c release --triple riscv32-none-none-eabi \
    -Xswiftc -enable-experimental-feature -Xswiftc Embedded \
    -Xcc -I/path/to/esp-idf/components/esp_common/include \
    -Xcc -I/path/to/esp-idf/components/freertos/include

# Note: Exact include paths and linking will be refined during implementation
```

## Verification Tests

### Test 1: Swift Toolchain
```bash
# Verify Swift Embedded feature is available
swift -version
# Should show development snapshot

# Test embedded compilation
echo '@main struct Test { static func main() { print("test") } }' > test.swift
swift -frontend -c test.swift -enable-experimental-feature Embedded
# Should compile without errors
rm test.swift test.o
```

### Test 2: ESP-IDF Environment
```bash
# Activate ESP-IDF
get_idf

# Verify ESP-IDF variables
echo $IDF_PATH
echo $IDF_TARGET
# Should show ESP-IDF paths and esp32c6 target

# Test basic ESP-IDF build
idf.py --version
# Should show ESP-IDF version 5.3+
```

### Test 3: Cross-Platform Compilation Test
```bash
# Create minimal embedded program
mkdir swift-embedded-test
cd swift-embedded-test

# Create test program
cat > main.swift << 'EOF'
@main
struct EmbeddedTest {
    static func main() {
        // Minimal embedded program
        var counter: UInt32 = 0
        while counter < 10 {
            counter += 1
        }
    }
}
EOF

# Test compilation with embedded flags
swift -frontend -c main.swift \
    -enable-experimental-feature Embedded \
    -target riscv32-none-none-eabi

# Clean up
cd ..
rm -rf swift-embedded-test
```

## IDE Setup

### Xcode Setup (macOS)
1. Open Xcode
2. Go to Preferences > Components > Toolchains
3. Select the Swift development snapshot
4. Create new project with Swift Package Manager
5. Add embedded Swift settings to Package.swift

### VS Code Setup (macOS/Linux)
```bash
# Install Swift extension
code --install-extension sswg.swift-lang

# Create workspace settings
mkdir .vscode
cat > .vscode/settings.json << 'EOF'
{
    "swift.path": "/opt/swift/usr/bin/swift",
    "swift.buildArguments": [
        "-Xswiftc", "-enable-experimental-feature",
        "-Xswiftc", "Embedded"
    ]
}
EOF
```

## Troubleshooting

### Common Issues

#### "Embedded feature not available"
- **Cause**: Using release toolchain instead of development snapshot
- **Solution**: Install development snapshot from swift.org

#### ESP-IDF not found
- **Cause**: Environment variables not set
- **Solution**: Run `get_idf` command to activate ESP-IDF environment

#### Cross-compilation errors
- **Cause**: Missing target or incorrect flags
- **Solution**: Verify RISC-V target and embedded flags are correct

#### Permission denied on Linux
- **Cause**: USB device permissions
- **Solution**: Add user to dialout group: `sudo usermod -a -G dialout $USER`

### Verification Commands
```bash
# Complete environment check
echo "Swift version:"
swift --version

echo "ESP-IDF path:"
echo $IDF_PATH

echo "ESP-IDF target:"
echo $IDF_TARGET

echo "USB devices:"
ls /dev/tty* | grep -E "(USB|ACM)"

# Test basic embedded compilation
swift -frontend -version | grep -i embedded
```

## Next Steps

1. **Test Hardware Connection**: Connect ESP32-C6 board and verify recognition
2. **Create Hello World Project**: Build and flash minimal Swift Embedded firmware
3. **Integration Testing**: Verify ESPHome Swift can use this environment
4. **Performance Validation**: Benchmark compilation speed and binary size

## Environment Variables Reference

### Essential Variables
```bash
export IDF_PATH="$HOME/esp/esp-idf"
export IDF_TARGET="esp32c6"
export PATH="$IDF_PATH/tools:$PATH"
export PATH="/opt/swift/usr/bin:$PATH"  # Linux
```

### Development Shortcuts
```bash
# Add to shell profile (.bashrc, .zshrc)
alias swift-embedded='swift -Xswiftc -enable-experimental-feature -Xswiftc Embedded'
alias esp-setup='source ~/esp/esp-idf/export.sh'
alias build-esp32='swift build -c release --triple riscv32-none-none-eabi'
```

---

**Status**: Ready for implementation testing  
**Next**: Hardware connection and first Swift Embedded compilation test