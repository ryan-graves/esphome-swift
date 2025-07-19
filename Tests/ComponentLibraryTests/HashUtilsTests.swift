import XCTest
@testable import ComponentLibrary

final class HashUtilsTests: XCTestCase {
    
    func testFNV1aHashConsistency() throws {
        // Test that the same input always produces the same hash
        let input = "test_string"
        let hash1 = HashUtils.fnv1aHash(input)
        let hash2 = HashUtils.fnv1aHash(input)
        
        XCTAssertEqual(hash1, hash2, "FNV-1a hash should be consistent")
    }
    
    func testFNV1aHashUniqueness() throws {
        // Test that different inputs produce different hashes
        let hash1 = HashUtils.fnv1aHash("test1")
        let hash2 = HashUtils.fnv1aHash("test2")
        
        XCTAssertNotEqual(hash1, hash2, "Different inputs should produce different hashes")
    }
    
    func testComponentKeyGeneration() throws {
        // Test component key generation
        let key1 = HashUtils.generateComponentKey(name: "sensor1", type: "temperature")
        let key2 = HashUtils.generateComponentKey(name: "sensor2", type: "temperature")
        let key3 = HashUtils.generateComponentKey(name: "sensor1", type: "humidity")
        
        // All keys should be different
        XCTAssertNotEqual(key1, key2, "Different names should produce different keys")
        XCTAssertNotEqual(key1, key3, "Different types should produce different keys")
        XCTAssertNotEqual(key2, key3, "Different combinations should produce different keys")
        
        // Keys should never be zero
        XCTAssertNotEqual(key1, 0, "Component key should never be zero")
        XCTAssertNotEqual(key2, 0, "Component key should never be zero")
        XCTAssertNotEqual(key3, 0, "Component key should never be zero")
    }
    
    func testComponentKeyConsistency() throws {
        // Test that the same name/type combination always produces the same key
        let key1 = HashUtils.generateComponentKey(name: "test_sensor", type: "temperature")
        let key2 = HashUtils.generateComponentKey(name: "test_sensor", type: "temperature")
        
        XCTAssertEqual(key1, key2, "Same name/type should produce consistent keys")
    }
    
    func testEmptyStringHash() throws {
        // Test edge case with empty strings
        let emptyHash = HashUtils.fnv1aHash("")
        let componentKey = HashUtils.generateComponentKey(name: "", type: "")
        
        // Should handle empty strings gracefully
        XCTAssertNotEqual(componentKey, 0, "Even empty input should not produce zero key")
        XCTAssertGreaterThan(emptyHash, 0, "Empty string should still produce valid hash")
    }
}