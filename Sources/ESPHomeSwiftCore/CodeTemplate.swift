import Foundation

// MARK: - Secure Code Generation Templates

/// Protocol for code template generation
public protocol CodeTemplate {
    var templateContent: String { get }
    func render(with parameters: [String: TemplateValue]) throws -> String
}

/// Safe template value types
@frozen
public enum TemplateValue {
    case string(String)
    case integer(Int)
    case boolean(Bool)
    case identifier(String)
    case pinNumber(Int)
    
    /// Get escaped value for C++ code generation
    var cppValue: String {
        switch self {
        case .string(let value):
            return escapeForCpp(value)
        case .integer(let value):
            return String(value)
        case .boolean(let value):
            return value ? "true" : "false"
        case .identifier(let value):
            return sanitizeIdentifier(value)
        case .pinNumber(let value):
            return "GPIO_NUM_\(value)"
        }
    }
    
    /// Escape string values for safe C++ inclusion
    private func escapeForCpp(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
    
    /// Sanitize identifier names for C++ compatibility
    private func sanitizeIdentifier(_ input: String) -> String {
        let cleaned = input
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        
        // Ensure identifier doesn't start with a number
        if cleaned.first?.isNumber == true {
            return "_" + cleaned
        }
        
        return cleaned.isEmpty ? "_unnamed" : cleaned
    }
}

/// Template rendering errors
public enum TemplateError: Error, LocalizedError {
    case missingParameter(String)
    case invalidTemplate(String)
    case renderingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingParameter(let param):
            return "Missing required template parameter: \(param)"
        case .invalidTemplate(let reason):
            return "Invalid template: \(reason)"
        case .renderingFailed(let reason):
            return "Template rendering failed: \(reason)"
        }
    }
}

/// Simple and secure template renderer
public struct ESP32CodeTemplate: CodeTemplate {
    public let templateContent: String
    private let requiredParameters: Set<String>
    
    public init(content: String, requiredParameters: [String] = []) {
        self.templateContent = content
        self.requiredParameters = Set(requiredParameters)
    }
    
    /// Render template with safe parameter substitution
    public func render(with parameters: [String: TemplateValue]) throws -> String {
        // Validate all required parameters are present
        for required in requiredParameters {
            guard parameters[required] != nil else {
                throw TemplateError.missingParameter(required)
            }
        }
        
        var result = templateContent
        
        // Replace parameters with escaped values
        for (key, value) in parameters {
            let placeholder = "{{\\(\(key))}}"
            result = result.replacingOccurrences(of: placeholder, with: value.cppValue)
        }
        
        // Check for any unreplaced parameters
        let unreplacedPattern = #"\{\{\\([^}]+)\}\}"#
        if let regex = try? NSRegularExpression(pattern: unreplacedPattern),
           regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil {
            throw TemplateError.renderingFailed("Unreplaced template parameters found")
        }
        
        return result
    }
}

// MARK: - Common ESP32 Code Templates

/// Collection of reusable ESP32 code templates
public enum ESP32Templates {
    
    /// GPIO input setup template
    public static let gpioInputSetup = ESP32CodeTemplate(
        content: """
        gpio_config_t io_conf = {};
        io_conf.intr_type = GPIO_INTR_DISABLE;
        io_conf.mode = GPIO_MODE_INPUT;
        io_conf.pin_bit_mask = (1ULL << {{\\(pin)}});
        io_conf.pull_down_en = 0;
        io_conf.pull_up_en = {{\\(pullup)}};
        gpio_config(&io_conf);
        """,
        requiredParameters: ["pin", "pullup"]
    )
    
    /// GPIO output setup template
    public static let gpioOutputSetup = ESP32CodeTemplate(
        content: """
        gpio_config_t io_conf = {};
        io_conf.intr_type = GPIO_INTR_DISABLE;
        io_conf.mode = GPIO_MODE_OUTPUT;
        io_conf.pin_bit_mask = (1ULL << {{\\(pin)}});
        io_conf.pull_down_en = 0;
        io_conf.pull_up_en = 0;
        gpio_config(&io_conf);
        gpio_set_level({{\\(pin)}}, {{\\(initialState)}});
        """,
        requiredParameters: ["pin", "initialState"]
    )
    
    /// Digital read template
    public static let digitalRead = ESP32CodeTemplate(
        content: """
        int {{\\(variableName)}} = gpio_get_level({{\\(pin)}});
        """,
        requiredParameters: ["variableName", "pin"]
    )
    
    /// Digital write template
    public static let digitalWrite = ESP32CodeTemplate(
        content: """
        gpio_set_level({{\\(pin)}}, {{\\(value)}});
        """,
        requiredParameters: ["pin", "value"]
    )
    
    /// DHT sensor reading template
    public static let dhtRead = ESP32CodeTemplate(
        content: """
        float {{\\(tempVar)}}, {{\\(humVar)}};
        if (dht_read_float_data({{\\(dhtType)}}, {{\\(pin)}}, &{{\\(humVar)}}, &{{\\(tempVar)}}) == ESP_OK) {
            printf("Temperature: %.1f°C, Humidity: %.1f%%\\n", {{\\(tempVar)}}, {{\\(humVar)}});
        } else {
            printf("Failed to read from DHT sensor\\n");
        }
        """,
        requiredParameters: ["tempVar", "humVar", "dhtType", "pin"]
    )
    
    /// PWM setup template
    public static let pwmSetup = ESP32CodeTemplate(
        content: """
        ledc_timer_config_t ledc_timer = {
            .speed_mode = LEDC_LOW_SPEED_MODE,
            .timer_num = {{\\(timerNum)}},
            .duty_resolution = LEDC_TIMER_{{\\(resolution)}}_BIT,
            .freq_hz = {{\\(frequency)}},
            .clk_cfg = LEDC_AUTO_CLK
        };
        ESP_ERROR_CHECK(ledc_timer_config(&ledc_timer));
        
        ledc_channel_config_t ledc_channel = {
            .speed_mode = LEDC_LOW_SPEED_MODE,
            .channel = {{\\(channel)}},
            .timer_sel = {{\\(timerNum)}},
            .intr_type = LEDC_INTR_DISABLE,
            .gpio_num = {{\\(pin)}},
            .duty = 0,
            .hpoint = 0
        };
        ESP_ERROR_CHECK(ledc_channel_config(&ledc_channel));
        """,
        requiredParameters: ["timerNum", "resolution", "frequency", "channel", "pin"]
    )
    
    /// PWM duty cycle update template
    public static let pwmUpdate = ESP32CodeTemplate(
        content: """
        ESP_ERROR_CHECK(ledc_set_duty(LEDC_LOW_SPEED_MODE, {{\\(channel)}}, {{\\(duty)}}));
        ESP_ERROR_CHECK(ledc_update_duty(LEDC_LOW_SPEED_MODE, {{\\(channel)}}));
        """,
        requiredParameters: ["channel", "duty"]
    )
}

// MARK: - Template Builder

/// Fluent interface for building code templates
public final class CodeTemplateBuilder {
    private var content: String = ""
    private var parameters: Set<String> = []
    
    public init() {}
    
    /// Add template content
    public func content(_ template: String) -> CodeTemplateBuilder {
        self.content = template
        return self
    }
    
    /// Add required parameter
    public func parameter(_ name: String) -> CodeTemplateBuilder {
        self.parameters.insert(name)
        return self
    }
    
    /// Add multiple required parameters
    public func parameters(_ names: String...) -> CodeTemplateBuilder {
        self.parameters.formUnion(names)
        return self
    }
    
    /// Build the final template
    public func build() -> ESP32CodeTemplate {
        return ESP32CodeTemplate(content: content, requiredParameters: Array(parameters))
    }
}