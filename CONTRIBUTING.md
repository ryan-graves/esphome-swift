# Contributing to ESPHome Swift

First off, thank you for considering contributing to ESPHome Swift! It's people like you that make ESPHome Swift such a great tool.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (configuration files, error messages, etc.)
- **Describe the behavior you observed and what you expected**
- **Include system information** (OS, Swift version, ESP32 board type)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the proposed enhancement**
- **Explain why this enhancement would be useful**
- **List any alternative solutions you've considered**

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding style** of the project
3. **Add tests** for any new functionality
4. **Update documentation** as needed
5. **Ensure all tests pass** locally
6. **Write a clear commit message** following conventional commits

## Development Setup

### Prerequisites

- Swift 5.9+ (Swift 6.0+ recommended)
- ESP-IDF v5.3+ (for testing firmware generation)
- macOS, Linux, or Windows development environment (full cross-platform support)

### Getting Started

1. Fork and clone the repository:
```bash
git clone git@github.com:YOUR_USERNAME/esphome-swift.git
cd esphome-swift
```

2. Set up upstream remote:
```bash
git remote add upstream git@github.com:ryan-graves/esphome-swift.git
```

3. Create and switch to develop branch:
```bash
git checkout -b develop origin/develop
```

4. Build the project:
```bash
swift build
```

5. Run tests:
```bash
swift test
```

6. Run the CLI:
```bash
swift run esphome-swift --help
```

### Branch Workflow

ESPHome Swift uses a Git Flow inspired branching strategy. **All contributions must follow this workflow:**

#### **For Features and Enhancements**

1. **Start from develop:**
```bash
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-description
```

2. **Make your changes and commit:**
```bash
git add .
git commit -m "feat: add your feature description"
```

3. **Push and create PR:**
```bash
git push origin feature/your-feature-description
# Create PR targeting 'develop' branch (NOT main)
```

#### **For Bug Fixes**

```bash
git checkout develop
git pull upstream develop
git checkout -b fix/bug-description
# Make changes, commit, push, and create PR to 'develop'
```

#### **For Documentation**

```bash
git checkout develop
git pull upstream develop
git checkout -b docs/documentation-update
# Make changes, commit, push, and create PR to 'develop'
```

#### **Branch Naming Convention**

- `feature/add-i2c-sensor-support`
- `fix/dht-timeout-issue`
- `docs/update-component-examples`
- Use kebab-case (lowercase with hyphens)
- Be descriptive but concise

**❌ Never create PRs directly to `main` branch**
**✅ Always target `develop` branch for contributions**

### Code Quality Tools

The project uses code quality tools to maintain consistent style:

#### SwiftLint (macOS only)
```bash
# Install SwiftLint
brew install swiftlint

# Run SwiftLint
swiftlint
```

#### SwiftFormat (Cross-platform)
```bash
# Install SwiftFormat
# macOS:
brew install swiftformat

# Linux:
curl -L https://github.com/nicklockwood/SwiftFormat/releases/latest/download/swiftformat_linux.zip -o swiftformat.zip
unzip swiftformat.zip && chmod +x swiftformat_linux && sudo mv swiftformat_linux /usr/local/bin/swiftformat

# Check formatting
swiftformat --lint .

# Auto-fix formatting
swiftformat .
```

## Project Structure

```
ESPHomeSwift/
├── Sources/
│   ├── ESPHomeSwiftCore/     # Core configuration & validation
│   ├── CodeGeneration/       # Swift code generation engine
│   ├── ComponentLibrary/     # Built-in component definitions
│   ├── CLI/                  # Command-line interface
│   └── WebDashboard/         # Web-based monitoring
├── Tests/                    # Unit and integration tests
├── Examples/                 # Example configurations
└── Resources/                # Templates and schemas
```

## Adding New Components

To add a new component (e.g., a new sensor type):

1. Create a new file in `Sources/ComponentLibrary/[ComponentType]/`
2. Implement the `ComponentFactory` protocol
3. Register your component in `ComponentRegistry.registerBuiltInComponents()`
4. Add tests in `Tests/ComponentLibraryTests/`
5. Update documentation and add an example

Example component implementation:
```swift
public class MyNewSensorFactory: ComponentFactory {
    public let platform = "my_sensor"
    public let componentType = ComponentType.sensor
    public let requiredProperties = ["pin"]
    public let optionalProperties = ["name", "update_interval"]
    
    public func validate(config: ComponentConfig) throws {
        // Validation logic
    }
    
    public func generateCode(config: ComponentConfig, context: CodeGenerationContext) throws -> ComponentCode {
        // Code generation logic
    }
}
```

## Testing

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **Example Validation**: Ensure all examples validate correctly

Run specific tests:
```bash
swift test --filter ESPHomeSwiftCoreTests
```

## Coding Style

The project uses automated code quality tools to enforce consistent style:

- **SwiftLint**: Enforces Swift best practices and style guidelines (macOS only)
- **SwiftFormat**: Handles code formatting automatically (cross-platform)

Manual style guidelines:
- Use Swift's naming conventions (camelCase for variables, PascalCase for types)
- Keep functions focused and small
- Document public APIs with comments
- Use meaningful variable names
- Follow Swift API Design Guidelines

**Before submitting a PR**: Run both `swiftlint` (on macOS) and `swiftformat --lint .` to ensure your code passes CI checks.

## Branching and Workflow Details

The branch workflow described above covers the essential contribution process. For maintainers and advanced contributors, additional workflow details are documented separately.

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, missing semicolons, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example:
```
feat: add support for BME280 temperature sensor

- Implement BME280 sensor factory
- Add I2C communication support
- Include temperature, humidity, and pressure readings
```

## Documentation

- Update README.md for significant changes
- Add inline documentation for public APIs
- Update component documentation when adding new components
- Include examples for new features

## Release Process

1. Ensure all tests pass
2. Update version numbers if needed
3. Create a pull request to `main`
4. After merge, create a tag: `git tag -a v1.0.0 -m "Release version 1.0.0"`
5. Push the tag: `git push origin v1.0.0`
6. GitHub Actions will automatically create the release

## Getting Help

- Check the [documentation](https://github.com/ryan-graves/esphome-swift/wiki)
- Look through existing [issues](https://github.com/ryan-graves/esphome-swift/issues)
- Join our [discussions](https://github.com/ryan-graves/esphome-swift/discussions)
- Ask questions in issues with the "question" label

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- The contributors page

Thank you for contributing to ESPHome Swift! 🎉