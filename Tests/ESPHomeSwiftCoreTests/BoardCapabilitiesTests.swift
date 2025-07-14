import XCTest
@testable import ESPHomeSwiftCore

final class BoardCapabilitiesTests: XCTestCase {

    func testBoardDefinitionsExist() {
        // Test that all expected boards are defined
        let expectedBoards = [
            "esp32-c3-devkitm-1",
            "esp32-c3-devkitc-02", 
            "esp32-c6-devkitc-1",
            "esp32-c6-devkitm-1",
            "esp32-h2-devkitc-1",
            "esp32-h2-devkitm-1",
            "esp32-p4-function-ev-board"
        ]
        
        for board in expectedBoards {
            XCTAssertNotNil(BoardCapabilities.boardDefinition(for: board), "Board \(board) should be defined")
        }
    }
    
    func testMatterCapableBoards() {
        let matterBoards = BoardCapabilities.matterCapableBoards
        
        // ESP32-C6 and ESP32-H2 should support Matter
        XCTAssertTrue(matterBoards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(matterBoards.contains("esp32-c6-devkitm-1"))
        XCTAssertTrue(matterBoards.contains("esp32-h2-devkitc-1"))
        XCTAssertTrue(matterBoards.contains("esp32-h2-devkitm-1"))
        
        // ESP32-C3 and ESP32-P4 should not support Matter
        XCTAssertFalse(matterBoards.contains("esp32-c3-devkitm-1"))
        XCTAssertFalse(matterBoards.contains("esp32-c3-devkitc-02"))
        XCTAssertFalse(matterBoards.contains("esp32-p4-function-ev-board"))
    }
    
    func testThreadCapableBoards() {
        let threadBoards = BoardCapabilities.threadCapableBoards
        
        // ESP32-C6 and ESP32-H2 should support Thread
        XCTAssertTrue(threadBoards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(threadBoards.contains("esp32-c6-devkitm-1"))
        XCTAssertTrue(threadBoards.contains("esp32-h2-devkitc-1"))
        XCTAssertTrue(threadBoards.contains("esp32-h2-devkitm-1"))
        
        // ESP32-C3 and ESP32-P4 should not support Thread
        XCTAssertFalse(threadBoards.contains("esp32-c3-devkitm-1"))
        XCTAssertFalse(threadBoards.contains("esp32-c3-devkitc-02"))
        XCTAssertFalse(threadBoards.contains("esp32-p4-function-ev-board"))
    }
    
    func testBoardCapabilityQueries() {
        // Test WiFi capability
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .wifi))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .wifi))
        XCTAssertFalse(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .wifi))
        
        // Test Thread capability
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .thread))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .thread))
        XCTAssertFalse(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .thread))
        
        // Test ADC capability (all boards should have this)
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .adc))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .adc))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .adc))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-p4-function-ev-board", capability: .adc))
    }
    
    func testChipFamilyGrouping() {
        let c6Boards = BoardCapabilities.boards(for: .esp32c6)
        XCTAssertTrue(c6Boards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(c6Boards.contains("esp32-c6-devkitm-1"))
        XCTAssertFalse(c6Boards.contains("esp32-c3-devkitm-1"))
        
        let h2Boards = BoardCapabilities.boards(for: .esp32h2)
        XCTAssertTrue(h2Boards.contains("esp32-h2-devkitc-1"))
        XCTAssertTrue(h2Boards.contains("esp32-h2-devkitm-1"))
        XCTAssertFalse(h2Boards.contains("esp32-c6-devkitc-1"))
    }
    
    func testPinConstraints() {
        // Test ESP32-C6 pin constraints
        guard let c6Board = BoardCapabilities.boardDefinition(for: "esp32-c6-devkitc-1") else {
            XCTFail("ESP32-C6 board definition not found")
            return
        }
        
        XCTAssertTrue(c6Board.pinConstraints.availableGPIOPins.contains(0))
        XCTAssertTrue(c6Board.pinConstraints.availableGPIOPins.contains(30))
        XCTAssertTrue(c6Board.pinConstraints.adcCapablePins.contains(0))
        XCTAssertTrue(c6Board.pinConstraints.adcCapablePins.contains(7))
        XCTAssertTrue(c6Board.pinConstraints.inputOnlyPins.contains(18))
        XCTAssertTrue(c6Board.pinConstraints.inputOnlyPins.contains(19))
        
        // Test ESP32-C3 pin constraints
        guard let c3Board = BoardCapabilities.boardDefinition(for: "esp32-c3-devkitm-1") else {
            XCTFail("ESP32-C3 board definition not found")
            return
        }
        
        XCTAssertTrue(c3Board.pinConstraints.availableGPIOPins.contains(0))
        XCTAssertTrue(c3Board.pinConstraints.availableGPIOPins.contains(21))
        XCTAssertTrue(c3Board.pinConstraints.adcCapablePins.contains(0))
        XCTAssertTrue(c3Board.pinConstraints.adcCapablePins.contains(4))
        XCTAssertFalse(c3Board.pinConstraints.adcCapablePins.contains(5)) // Not ADC on C3
        
        // Test ESP32-H2 pin constraints
        guard let h2Board = BoardCapabilities.boardDefinition(for: "esp32-h2-devkitc-1") else {
            XCTFail("ESP32-H2 board definition not found")
            return
        }
        
        XCTAssertTrue(h2Board.pinConstraints.availableGPIOPins.contains(0))
        XCTAssertTrue(h2Board.pinConstraints.availableGPIOPins.contains(27)) // GPIO0-27 (28 pins)
        XCTAssertFalse(h2Board.pinConstraints.availableGPIOPins.contains(28)) // Should not have GPIO28
        XCTAssertTrue(h2Board.pinConstraints.inputOnlyPins.isEmpty) // No input-only pins
        XCTAssertTrue(h2Board.pinConstraints.adcCapablePins.contains(0))
        XCTAssertTrue(h2Board.pinConstraints.adcCapablePins.contains(4))
        XCTAssertFalse(h2Board.pinConstraints.adcCapablePins.contains(5)) // Only GPIO0-4 for ADC
        
        // Test ESP32-P4 pin constraints
        guard let p4Board = BoardCapabilities.boardDefinition(for: "esp32-p4-function-ev-board") else {
            XCTFail("ESP32-P4 board definition not found")
            return
        }
        
        XCTAssertTrue(p4Board.pinConstraints.availableGPIOPins.contains(0))
        XCTAssertTrue(p4Board.pinConstraints.availableGPIOPins.contains(54)) // GPIO0-54 (55 pins)
        XCTAssertFalse(p4Board.pinConstraints.availableGPIOPins.contains(55)) // Should not have GPIO55
        XCTAssertTrue(p4Board.pinConstraints.inputOnlyPins.isEmpty) // No input-only pins
        XCTAssertTrue(p4Board.pinConstraints.adcCapablePins.contains(0))
        XCTAssertTrue(p4Board.pinConstraints.adcCapablePins.contains(7))
        XCTAssertFalse(p4Board.pinConstraints.adcCapablePins.contains(8)) // Only GPIO0-7 for ADC
    }
    
    func testMatterExtensions() {
        // Test Matter support query
        XCTAssertTrue(BoardCapabilities.supportsMatter("esp32-c6-devkitc-1"))
        XCTAssertTrue(BoardCapabilities.supportsMatter("esp32-h2-devkitc-1"))
        XCTAssertFalse(BoardCapabilities.supportsMatter("esp32-c3-devkitm-1"))
        XCTAssertFalse(BoardCapabilities.supportsMatter("nonexistent-board"))
        
        // Test Thread support query
        XCTAssertTrue(BoardCapabilities.supportsThread("esp32-c6-devkitc-1"))
        XCTAssertTrue(BoardCapabilities.supportsThread("esp32-h2-devkitc-1"))
        XCTAssertFalse(BoardCapabilities.supportsThread("esp32-c3-devkitm-1"))
        XCTAssertFalse(BoardCapabilities.supportsThread("nonexistent-board"))
    }
    
    func testBoardsWithCapability() {
        // Test WiFi boards
        let wifiBoards = BoardCapabilities.boardsWithCapability(.wifi)
        XCTAssertTrue(wifiBoards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(wifiBoards.contains("esp32-c3-devkitm-1"))
        XCTAssertFalse(wifiBoards.contains("esp32-h2-devkitc-1")) // H2 has no WiFi
        
        // Test Bluetooth boards
        let bluetoothBoards = BoardCapabilities.boardsWithCapability(.bluetooth)
        XCTAssertTrue(bluetoothBoards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(bluetoothBoards.contains("esp32-c3-devkitm-1"))
        XCTAssertTrue(bluetoothBoards.contains("esp32-h2-devkitc-1"))
        XCTAssertFalse(bluetoothBoards.contains("esp32-p4-function-ev-board")) // P4 has no wireless
    }
    
    func testAllSupportedBoards() {
        let allBoards = BoardCapabilities.allSupportedBoards
        
        XCTAssertTrue(allBoards.count >= 7) // At least 7 boards defined
        XCTAssertTrue(allBoards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(allBoards.contains("esp32-c3-devkitm-1"))
        XCTAssertTrue(allBoards.contains("esp32-h2-devkitc-1"))
        XCTAssertTrue(allBoards.contains("esp32-p4-function-ev-board"))
        
        // Should be sorted
        XCTAssertEqual(allBoards, allBoards.sorted())
    }
    
    func testDisplayNames() {
        guard let c6Board = BoardCapabilities.boardDefinition(for: "esp32-c6-devkitc-1") else {
            XCTFail("ESP32-C6 board definition not found")
            return
        }
        
        XCTAssertEqual(c6Board.displayName, "ESP32-C6 DevKit-C")
        XCTAssertEqual(c6Board.chipFamily, .esp32c6)
        XCTAssertEqual(c6Board.architecture, .riscv)
    }
    
    func testZigbeeCapability() {
        // Test Zigbee capability - ESP32-C6 and ESP32-H2 should support it
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .zigbee))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitm-1", capability: .zigbee))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .zigbee))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitm-1", capability: .zigbee))
        
        // ESP32-C3 and ESP32-P4 should not support Zigbee
        XCTAssertFalse(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .zigbee))
        XCTAssertFalse(BoardCapabilities.boardSupports("esp32-c3-devkitc-02", capability: .zigbee))
        XCTAssertFalse(BoardCapabilities.boardSupports("esp32-p4-function-ev-board", capability: .zigbee))
        
        // Test that C6 and H2 boards appear in Zigbee-capable boards list
        let zigbeeBoards = BoardCapabilities.boardsWithCapability(.zigbee)
        XCTAssertTrue(zigbeeBoards.contains("esp32-c6-devkitc-1"))
        XCTAssertTrue(zigbeeBoards.contains("esp32-c6-devkitm-1"))
        XCTAssertTrue(zigbeeBoards.contains("esp32-h2-devkitc-1"))
        XCTAssertTrue(zigbeeBoards.contains("esp32-h2-devkitm-1"))
        XCTAssertEqual(zigbeeBoards.count, 4) // 2 C6 boards + 2 H2 boards should support Zigbee
    }
    
    func testCaseInsensitiveBoardLookup() {
        // Test that board lookups work with different case variations
        let testVariations = [
            "ESP32-C6-DEVKITC-1",
            "Esp32-C6-DevKitC-1", 
            "esp32-c6-devkitc-1",
            "ESP32-c6-DEVKITC-1"
        ]
        
        for variation in testVariations {
            XCTAssertTrue(BoardCapabilities.boardSupports(variation, capability: .wifi), 
                         "Board lookup should be case-insensitive for: \(variation)")
            XCTAssertNotNil(BoardCapabilities.boardDefinition(for: variation),
                            "Board definition lookup should be case-insensitive for: \(variation)")
        }
        
        // Test that the returned board definition is the same regardless of case
        let lowerBoard = BoardCapabilities.boardDefinition(for: "esp32-c6-devkitc-1")
        let upperBoard = BoardCapabilities.boardDefinition(for: "ESP32-C6-DEVKITC-1")
        
        XCTAssertEqual(lowerBoard?.identifier, upperBoard?.identifier)
        XCTAssertEqual(lowerBoard?.displayName, upperBoard?.displayName)
    }
}