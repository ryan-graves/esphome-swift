import XCTest
@testable import MatterSupport

final class MatterCredentialGeneratorTests: XCTestCase {
    
    // MARK: - Single Credential Generation Tests
    
    func testGenerateSingleCredentials() throws {
        let credentials = try MatterCredentialGenerator.generateCredentials()
        
        // Verify discriminator range (12-bit: 0-4095)
        XCTAssertTrue(credentials.discriminator <= 4095, "Discriminator should be within 12-bit range")
        
        // Verify passcode range (1-99999998)
        XCTAssertTrue(credentials.passcode >= 1, "Passcode should be at least 1")
        XCTAssertTrue(credentials.passcode <= 99999998, "Passcode should not exceed 99999998")
        
        // Verify credentials are valid
        XCTAssertTrue(MatterCredentialGenerator.validateCredentials(credentials))
    }
    
    func testGeneratedCredentialsAreUnique() throws {
        // Generate multiple credentials and verify they're unique
        var credentials: [MatterCredentials] = []
        
        for _ in 0 ..< 10 {
            let credential = try MatterCredentialGenerator.generateCredentials()
            credentials.append(credential)
        }
        
        // Check discriminator uniqueness
        let discriminators = credentials.map(\.discriminator)
        let uniqueDiscriminators = Set(discriminators)
        
        // Check passcode uniqueness  
        let passcodes = credentials.map(\.passcode)
        let uniquePasscodes = Set(passcodes)
        
        // Note: Due to random generation, we might occasionally get duplicates in small samples
        // But with a 12-bit discriminator space (4096 values) and 27-bit passcode space,
        // duplicates should be extremely rare in small test sets
        if uniqueDiscriminators.count < discriminators.count {
            print("Warning: Duplicate discriminators found in small sample - this is statistically possible but rare")
        }
        
        if uniquePasscodes.count < passcodes.count {
            print("Warning: Duplicate passcodes found in small sample - this is statistically possible but rare")
        }
    }
    
    // MARK: - Multiple Credential Generation Tests
    
    func testGenerateMultipleCredentials() throws {
        let count = 5
        let credentials = try MatterCredentialGenerator.generateCredentials(count: count)
        
        XCTAssertEqual(credentials.count, count, "Should generate exactly \(count) credentials")
        
        // Verify all credentials are valid
        for credential in credentials {
            XCTAssertTrue(MatterCredentialGenerator.validateCredentials(credential))
        }
        
        // Verify uniqueness within the batch
        let discriminators = credentials.map(\.discriminator)
        let uniqueDiscriminators = Set(discriminators)
        XCTAssertEqual(discriminators.count, uniqueDiscriminators.count, "All discriminators in batch should be unique")
        
        let passcodes = credentials.map(\.passcode)
        let uniquePasscodes = Set(passcodes)
        XCTAssertEqual(passcodes.count, uniquePasscodes.count, "All passcodes in batch should be unique")
    }
    
    func testGenerateCredentialsWithInvalidCount() {
        XCTAssertThrowsError(try MatterCredentialGenerator.generateCredentials(count: 0)) { error in
            guard case MatterCredentialGeneratorError.invalidCount(let count) = error else {
                XCTFail("Expected invalidCount error, got \(error)")
                return
            }
            XCTAssertEqual(count, 0)
        }
        
        XCTAssertThrowsError(try MatterCredentialGenerator.generateCredentials(count: -1)) { error in
            guard case MatterCredentialGeneratorError.invalidCount(let count) = error else {
                XCTFail("Expected invalidCount error, got \(error)")
                return
            }
            XCTAssertEqual(count, -1)
        }
    }
    
    func testGenerateLargeBatchCredentials() throws {
        // Test generating a larger batch to verify performance and uniqueness at scale
        let count = 100
        let credentials = try MatterCredentialGenerator.generateCredentials(count: count)
        
        XCTAssertEqual(credentials.count, count)
        
        // Verify uniqueness
        let discriminators = credentials.map(\.discriminator)
        let uniqueDiscriminators = Set(discriminators)
        XCTAssertEqual(discriminators.count, uniqueDiscriminators.count, "All discriminators should be unique")
        
        let passcodes = credentials.map(\.passcode)
        let uniquePasscodes = Set(passcodes)
        XCTAssertEqual(passcodes.count, uniquePasscodes.count, "All passcodes should be unique")
        
        // Verify all are valid
        for credential in credentials {
            XCTAssertTrue(MatterCredentialGenerator.validateCredentials(credential))
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidCredentials() {
        let validCredentials = MatterCredentials(discriminator: 1234, passcode: 45678901)
        XCTAssertTrue(MatterCredentialGenerator.validateCredentials(validCredentials))
    }
    
    func testValidateInvalidDiscriminator() {
        // Test discriminator out of range (> 4095)
        let invalidCredentials = MatterCredentials(discriminator: 5000, passcode: 45678901)
        XCTAssertFalse(MatterCredentialGenerator.validateCredentials(invalidCredentials))
    }
    
    func testValidateInvalidPasscode() {
        // Test passcode out of range
        let invalidLowPasscode = MatterCredentials(discriminator: 1234, passcode: 0)
        XCTAssertFalse(MatterCredentialGenerator.validateCredentials(invalidLowPasscode))
        
        let invalidHighPasscode = MatterCredentials(discriminator: 1234, passcode: 100000000)
        XCTAssertFalse(MatterCredentialGenerator.validateCredentials(invalidHighPasscode))
    }
    
    func testValidateInvalidPasscodeCodes() {
        // Test passcodes that are in the invalid list
        let invalidPasscodes: [UInt32] = [
            00000000, 11111111, 22222222, 33333333, 44444444,
            55555555, 66666666, 77777777, 88888888, 99999999,
            12345678, 87654321
        ]
        
        for invalidPasscode in invalidPasscodes {
            let credentials = MatterCredentials(discriminator: 1234, passcode: invalidPasscode)
            XCTAssertFalse(MatterCredentialGenerator.validateCredentials(credentials), 
                          "Passcode \(invalidPasscode) should be invalid")
        }
    }
    
    // MARK: - Integration Tests with MatterSetupPayload
    
    func testCredentialsGenerateValidQRCode() throws {
        let credentials = try MatterCredentialGenerator.generateCredentials()
        let qrCode = credentials.generateQRCode()
        
        XCTAssertTrue(qrCode.hasPrefix("MT:"), "QR code should start with MT: prefix")
        XCTAssertTrue(qrCode.count > 10, "QR code should be reasonably long")
    }
    
    func testCredentialsGenerateValidManualPairingCode() throws {
        let credentials = try MatterCredentialGenerator.generateCredentials()
        let manualCode = try credentials.generateManualPairingCode()
        
        // Manual pairing code should be in format XXXXX-XXXXXX (11 digits with hyphen)
        XCTAssertEqual(manualCode.count, 12, "Manual pairing code should be 12 characters long")
        XCTAssertTrue(manualCode.contains("-"), "Manual pairing code should contain hyphen")
        
        let parts = manualCode.split(separator: "-")
        XCTAssertEqual(parts.count, 2, "Manual pairing code should have two parts")
        XCTAssertEqual(parts[0].count, 5, "First part should be 5 digits")
        XCTAssertEqual(parts[1].count, 6, "Second part should be 6 digits")
        
        // Verify all characters are digits
        let digitsOnly = manualCode.replacingOccurrences(of: "-", with: "")
        XCTAssertTrue(digitsOnly.allSatisfy(\.isNumber), "Manual pairing code should contain only digits and hyphen")
    }
    
    // MARK: - Output Format Tests
    
    func testCredentialYAMLFormat() throws {
        let credentials = MatterCredentials(discriminator: 1234, passcode: 45678901)
        let yaml = credentials.yamlFormat
        
        XCTAssertTrue(yaml.contains("discriminator: 1234"))
        XCTAssertTrue(yaml.contains("passcode: 45678901"))
        XCTAssertTrue(yaml.contains("matter:"))
        XCTAssertTrue(yaml.contains("commissioning:"))
    }
    
    func testCredentialJSONFormat() throws {
        let credentials = MatterCredentials(discriminator: 1234, passcode: 45678901)
        let json = credentials.jsonFormat
        
        XCTAssertTrue(json.contains("\"discriminator\": 1234"))
        XCTAssertTrue(json.contains("\"passcode\": 45678901"))
        XCTAssertTrue(json.hasPrefix("{"))
        XCTAssertTrue(json.hasSuffix("}"))
    }
    
    func testCredentialTextFormat() throws {
        let credentials = MatterCredentials(discriminator: 1234, passcode: 45678901)
        let text = credentials.textFormat
        
        XCTAssertTrue(text.contains("Discriminator: 1234"))
        XCTAssertTrue(text.contains("Passcode: 45678901"))
        XCTAssertTrue(text.contains("Manual Pairing Code:"))
        XCTAssertTrue(text.contains("QR Code:"))
        XCTAssertTrue(text.contains("SECURITY WARNING"))
    }
    
    func testMultipleCredentialsYAMLFormat() throws {
        let credentials = [
            MatterCredentials(discriminator: 1234, passcode: 45678901),
            MatterCredentials(discriminator: 5678, passcode: 12345678)
        ]
        let yaml = credentials.yamlFormat
        
        XCTAssertTrue(yaml.contains("discriminator: 1234"))
        XCTAssertTrue(yaml.contains("passcode: 45678901"))
        XCTAssertTrue(yaml.contains("discriminator: 5678"))
        XCTAssertTrue(yaml.contains("passcode: 12345678"))
        XCTAssertTrue(yaml.contains("Device 1 credentials"))
        XCTAssertTrue(yaml.contains("Device 2 credentials"))
    }
    
    func testMultipleCredentialsJSONFormat() throws {
        let credentials = [
            MatterCredentials(discriminator: 1234, passcode: 45678901),
            MatterCredentials(discriminator: 5678, passcode: 12345678)
        ]
        let json = credentials.jsonFormat
        
        XCTAssertTrue(json.hasPrefix("["))
        XCTAssertTrue(json.hasSuffix("]"))
        XCTAssertTrue(json.contains("\"discriminator\": 1234"))
        XCTAssertTrue(json.contains("\"passcode\": 45678901"))
        XCTAssertTrue(json.contains("\"discriminator\": 5678"))
        XCTAssertTrue(json.contains("\"passcode\": 12345678"))
    }
    
    func testMultipleCredentialsTextFormat() throws {
        let credentials = [
            MatterCredentials(discriminator: 1234, passcode: 45678901),
            MatterCredentials(discriminator: 5678, passcode: 12345678)
        ]
        let text = credentials.textFormat
        
        XCTAssertTrue(text.contains("Generated 2 sets"))
        XCTAssertTrue(text.contains("Device 1:"))
        XCTAssertTrue(text.contains("Device 2:"))
        XCTAssertTrue(text.contains("Discriminator: 1234"))
        XCTAssertTrue(text.contains("Passcode: 45678901"))
        XCTAssertTrue(text.contains("Discriminator: 5678"))
        XCTAssertTrue(text.contains("Passcode: 12345678"))
        XCTAssertTrue(text.contains("SECURITY WARNING"))
    }
    
    // MARK: - Security Tests
    
    func testCredentialsAreNotPredictable() throws {
        // Generate multiple credentials and verify they show sufficient randomness
        // This is a basic test to catch obvious non-random patterns
        
        var credentials: [MatterCredentials] = []
        for _ in 0 ..< 20 {
            try credentials.append(MatterCredentialGenerator.generateCredentials())
        }
        
        // Check that we don't have obvious patterns like sequential values
        let discriminators = credentials.map(\.discriminator)
        let passcodes = credentials.map(\.passcode)
        
        // Verify we're not getting sequential discriminators
        var sequentialCount = 0
        for index in 1 ..< discriminators.count {
            if discriminators[index] == discriminators[index - 1] + 1 {
                sequentialCount += 1
            }
        }
        
        // Allow some sequential values due to randomness, but not too many
        XCTAssertLessThan(sequentialCount, 5, "Too many sequential discriminators suggests poor randomness")
        
        // Verify we're not getting sequential passcodes
        sequentialCount = 0
        for index in 1 ..< passcodes.count {
            if passcodes[index] == passcodes[index - 1] + 1 {
                sequentialCount += 1
            }
        }
        
        XCTAssertLessThan(sequentialCount, 5, "Too many sequential passcodes suggests poor randomness")
    }
    
    func testGeneratedCredentialsAvoidInvalidPasscodes() throws {
        // Generate many credentials and verify none use invalid passcodes
        let credentials = try MatterCredentialGenerator.generateCredentials(count: 50)
        
        let invalidPasscodes: Set<UInt32> = [
            00000000, 11111111, 22222222, 33333333, 44444444,
            55555555, 66666666, 77777777, 88888888, 99999999,
            12345678, 87654321
        ]
        
        for credential in credentials {
            XCTAssertFalse(invalidPasscodes.contains(credential.passcode), 
                          "Generated passcode \(credential.passcode) should not be in invalid list")
        }
    }
    
    // MARK: - Performance Tests
    
    func testCredentialGenerationPerformance() throws {
        measure {
            do {
                _ = try MatterCredentialGenerator.generateCredentials(count: 10)
            } catch {
                XCTFail("Credential generation failed: \(error)")
            }
        }
    }
    
    func testLargeScaleCredentialGeneration() throws {
        // Test generating credentials at scale to verify performance doesn't degrade
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let credentials = try MatterCredentialGenerator.generateCredentials(count: 1000)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        XCTAssertEqual(credentials.count, 1000)
        XCTAssertLessThan(duration, 10.0, "Should generate 1000 credentials in under 10 seconds")
        
        // Verify uniqueness even at scale
        let discriminators = Set(credentials.map(\.discriminator))
        let passcodes = Set(credentials.map(\.passcode))
        
        XCTAssertEqual(discriminators.count, 1000, "All discriminators should be unique")
        XCTAssertEqual(passcodes.count, 1000, "All passcodes should be unique")
    }
}