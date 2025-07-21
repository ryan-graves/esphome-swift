# Docker Development Environment for Swift Embedded

This guide explains how to use Docker for Swift Embedded development in ESPHome Swift, protecting your system while enabling full Swift Embedded capabilities.

## Why Docker?

Using Docker for Swift Embedded development provides:
- **System Protection**: No modifications to your macOS or system Swift installation
- **Version Control**: Pin exact Swift development snapshot versions
- **Reproducibility**: Same environment for all developers
- **Easy Cleanup**: Just delete containers/images if needed
- **Cross-Platform**: Works on macOS, Linux, and Windows

## Prerequisites

- Docker Desktop installed and running
- Basic familiarity with terminal commands

## Quick Start

### 1. Start Docker Desktop
Make sure Docker Desktop is running (you should see the whale icon in your menu bar).

### 2. Enter Development Shell
```bash
./docker/scripts/dev.sh
```

This command:
- Builds the Docker image (first time only)
- Starts a container with Swift Embedded
- Mounts your project directory
- Gives you a bash shell inside the container

### 3. Build the Project
Inside the container:
```bash
swift build
```

Or from your Mac terminal:
```bash
./docker/scripts/build.sh
```

### 4. Run Tests
Inside the container:
```bash
swift test
```

Or from your Mac terminal:
```bash
./docker/scripts/test.sh
```

## Common Commands

### Build Docker Image
```bash
docker-compose build swift-embedded
```

### Enter Development Shell
```bash
docker-compose run --rm swift-embedded /bin/bash
```

### Build Project
```bash
docker-compose run --rm swift-embedded swift build
```

### Run Tests
```bash
docker-compose run --rm swift-embedded swift test
```

### Clean Up Everything
```bash
docker-compose down -v
docker rmi esphome-swift:embedded
```

## Understanding the Setup

### Dockerfile
- Based on Ubuntu 22.04 LTS
- Includes Swift development snapshot with Embedded support
- Has ESP-IDF tools for ESP32 compilation
- Includes Python tools for device flashing

### docker-compose.yml
- Defines the `swift-embedded` service
- Mounts project directory at `/workspace/esphome-swift`
- Uses a named volume for `.build` cache
- Configured for interactive development

### Volume Mounting
Your project directory is mounted into the container, so:
- Changes you make on your Mac appear instantly in the container
- Files created in the container appear on your Mac
- Build artifacts are cached in a Docker volume for speed

## ESP32 Device Access

To flash ESP32 devices from the container, uncomment these lines in `docker-compose.yml`:
```yaml
privileged: true
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
  - /dev/tty.usbserial:/dev/tty.usbserial
```

Then find your device:
```bash
ls /dev/tty.* | grep -i usb
```

## Troubleshooting

### "Docker is not running"
Start Docker Desktop from your Applications folder.

### "Cannot connect to the Docker daemon"
Make sure Docker Desktop is fully started (whale icon is steady, not animated).

### Build takes forever
First build downloads and installs everything. Subsequent builds use cache.

### Permission denied errors
The container runs as root, so files created might have different permissions. Fix with:
```bash
sudo chown -R $(whoami) .
```

### Out of disk space
Clean up Docker resources:
```bash
docker system prune -a
```

## Advanced Usage

### Custom Swift Snapshot
Edit the `Dockerfile` to use a different Swift snapshot:
```dockerfile
ENV SWIFT_VERSION=swift-DEVELOPMENT-SNAPSHOT-2025-07-25-a
```

### VS Code Integration
Install the "Dev Containers" extension to develop inside the container with full IDE support.

### Multiple Swift Versions
Create additional Dockerfiles for different Swift versions:
```bash
docker build -f Dockerfile.swift6.3 -t esphome-swift:6.3 .
```

## Next Steps

1. Enable Swift Embedded flags in `Package.swift`
2. Build and test Swift Embedded components
3. Compile for ESP32 targets
4. Flash to actual hardware

Remember: Everything runs inside the container, keeping your system clean and safe!