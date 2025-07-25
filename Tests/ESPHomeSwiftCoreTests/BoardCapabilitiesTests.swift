import XCTest
@testable import ESPHomeSwiftCore
@testable import MatterSupport

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
        
        // Test PWM capability (all boards should have this)
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .pwm))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .pwm))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .pwm))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-p4-function-ev-board", capability: .pwm))
        
        // Test I2C capability (all boards should have this)
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .i2c))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .i2c))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .i2c))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-p4-function-ev-board", capability: .i2c))
        
        // Test SPI capability (all boards should have this)
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .spi))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .spi))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .spi))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-p4-function-ev-board", capability: .spi))
        
        // Test UART capability (all boards should have this)
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c6-devkitc-1", capability: .uart))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-c3-devkitm-1", capability: .uart))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-h2-devkitc-1", capability: .uart))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32-p4-function-ev-board", capability: .uart))
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
        
        // Test default peripheral pins match datasheet specifications
        
        // ESP32-C6 defaults
        XCTAssertEqual(c6Board.pinConstraints.i2cDefaultSDA, 5)
        XCTAssertEqual(c6Board.pinConstraints.i2cDefaultSCL, 6)
        XCTAssertEqual(c6Board.pinConstraints.spiDefaultMOSI, 7)
        XCTAssertEqual(c6Board.pinConstraints.spiDefaultMISO, 2)
        XCTAssertEqual(c6Board.pinConstraints.spiDefaultCLK, 6)
        XCTAssertEqual(c6Board.pinConstraints.spiDefaultCS, 10)
        
        // ESP32-C3 defaults
        XCTAssertEqual(c3Board.pinConstraints.i2cDefaultSDA, 5)
        XCTAssertEqual(c3Board.pinConstraints.i2cDefaultSCL, 6)
        XCTAssertEqual(c3Board.pinConstraints.spiDefaultMOSI, 7)
        XCTAssertEqual(c3Board.pinConstraints.spiDefaultMISO, 2)
        XCTAssertEqual(c3Board.pinConstraints.spiDefaultCLK, 6)
        XCTAssertEqual(c3Board.pinConstraints.spiDefaultCS, 10)
        
        // ESP32-H2 defaults (different from C6/C3)
        XCTAssertEqual(h2Board.pinConstraints.i2cDefaultSDA, 1)
        XCTAssertEqual(h2Board.pinConstraints.i2cDefaultSCL, 0)
        XCTAssertEqual(h2Board.pinConstraints.spiDefaultMOSI, 7)
        XCTAssertEqual(h2Board.pinConstraints.spiDefaultMISO, 2)
        XCTAssertEqual(h2Board.pinConstraints.spiDefaultCLK, 6)
        XCTAssertEqual(h2Board.pinConstraints.spiDefaultCS, 10)
        
        // ESP32-P4 defaults (different layout)
        XCTAssertEqual(p4Board.pinConstraints.i2cDefaultSDA, 8)
        XCTAssertEqual(p4Board.pinConstraints.i2cDefaultSCL, 9)
        XCTAssertEqual(p4Board.pinConstraints.spiDefaultMOSI, 11)
        XCTAssertEqual(p4Board.pinConstraints.spiDefaultMISO, 13)
        XCTAssertEqual(p4Board.pinConstraints.spiDefaultCLK, 12)
        XCTAssertEqual(p4Board.pinConstraints.spiDefaultCS, 10)
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
        
        // Verify that all Zigbee-capable boards are at least the expected ones
        XCTAssertGreaterThanOrEqual(zigbeeBoards.count, 4, "Should have at least 4 Zigbee-capable boards (2 C6 + 2 H2)")
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
    
    func testShorthandAliasSupport() {
        // Test shorthand aliases return default boards for each chip family
        let aliasTests = [
            ("esp32c3", "esp32-c3-devkitm-1"),
            ("ESP32-C3", "esp32-c3-devkitm-1"),
            ("esp32c6", "esp32-c6-devkitc-1"),
            ("ESP32-C6", "esp32-c6-devkitc-1"),
            ("esp32h2", "esp32-h2-devkitc-1"),
            ("ESP32-H2", "esp32-h2-devkitc-1"),
            ("esp32p4", "esp32-p4-function-ev-board"),
            ("ESP32-P4", "esp32-p4-function-ev-board")
        ]
        
        for (alias, expectedBoard) in aliasTests {
            guard let aliasBoard = BoardCapabilities.boardDefinition(for: alias),
                  let expectedBoardDef = BoardCapabilities.boardDefinition(for: expectedBoard) else {
                XCTFail("Failed to resolve alias '\(alias)' or expected board '\(expectedBoard)'")
                continue
            }
            
            XCTAssertEqual(aliasBoard.identifier, expectedBoardDef.identifier,
                           "Alias '\(alias)' should resolve to '\(expectedBoard)'")
            XCTAssertEqual(aliasBoard.chipFamily, expectedBoardDef.chipFamily,
                           "Alias '\(alias)' should have same chip family as '\(expectedBoard)'")
        }
        
        // Test that aliases support capability queries
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32c6", capability: .wifi))
        XCTAssertTrue(BoardCapabilities.boardSupports("esp32h2", capability: .thread))
        XCTAssertFalse(BoardCapabilities.boardSupports("esp32c3", capability: .matter))
    }
    
    func testMatterValidatorErrorHandling() {
        // Test MatterValidator.validate() throws correct errors for unsupported boards
        let matterConfig = MatterConfig(
            deviceType: "dimmable_light",
            vendorId: 0xFFF1,
            productId: 0x8000,
            commissioning: nil,
            thread: nil,
            network: nil
        )
        
        // Test unsupported board throws correct error
        XCTAssertThrowsError(try MatterValidator.validate(matterConfig, for: "esp32-c3-devkitm-1")) { error in
            guard let matterError = error as? MatterValidationError,
                  case .unsupportedBoard(let board, let reason) = matterError else {
                XCTFail("Expected MatterValidationError.unsupportedBoard, got \(error)")
                return
            }
            XCTAssertEqual(board, "esp32-c3-devkitm-1")
            XCTAssertTrue(reason.contains("esp32-c6-devkitc-1")) // Should contain supported boards
        }
        
        // Test supported board does not throw
        XCTAssertNoThrow(try MatterValidator.validate(matterConfig, for: "esp32-c6-devkitc-1"))
    }
    
    func testThreadValidatorErrorHandling() {
        // Test Thread validation through MatterValidator.validate() for unsupported boards
        let matterConfigWithThread = MatterConfig(
            deviceType: "dimmable_light",
            vendorId: 0xFFF1,
            productId: 0x8000,
            commissioning: nil,
            thread: ThreadConfig(
                enabled: true,
                dataset: nil,
                networkName: nil,
                extPanId: nil,
                networkKey: nil,
                channel: 15,
                panId: 0x1234
            ),
            network: nil
        )
        
        // Test that ESP32-C3 (non-Matter board) throws unsupportedBoard error first
        XCTAssertThrowsError(try MatterValidator.validate(matterConfigWithThread, for: "esp32-c3-devkitm-1")) { error in
            guard let matterError = error as? MatterValidationError,
                  case .unsupportedBoard(let board, let reason) = matterError else {
                XCTFail("Expected MatterValidationError.unsupportedBoard, got \(error)")
                return
            }
            XCTAssertEqual(board, "esp32-c3-devkitm-1")
            XCTAssertTrue(reason.contains("esp32-c6-devkitc-1")) // Should contain supported boards
        }
        
        // Test supported boards do not throw Thread errors
        XCTAssertNoThrow(try MatterValidator.validate(matterConfigWithThread, for: "esp32-c6-devkitc-1"))
        XCTAssertNoThrow(try MatterValidator.validate(matterConfigWithThread, for: "esp32-h2-devkitc-1"))
        
        // Test Thread validation specifically by testing with invalid channel on supported board
        let matterConfigInvalidThread = MatterConfig(
            deviceType: "dimmable_light",
            vendorId: 0xFFF1,
            productId: 0x8000,
            commissioning: nil,
            thread: ThreadConfig(
                enabled: true,
                dataset: nil,
                networkName: nil,
                extPanId: nil,
                networkKey: nil,
                channel: 99, // Invalid channel (should be 11-26)
                panId: 0x1234
            ),
            network: nil
        )
        
        // Test invalid Thread configuration throws correct error
        XCTAssertThrowsError(try MatterValidator.validate(matterConfigInvalidThread, for: "esp32-c6-devkitc-1")) { error in
            guard let matterError = error as? MatterValidationError,
                  case .invalidThreadParameter(let parameter, let value, let reason) = matterError else {
                XCTFail("Expected MatterValidationError.invalidThreadParameter, got \(error)")
                return
            }
            XCTAssertEqual(parameter, "channel")
            XCTAssertEqual(value, "99")
            XCTAssertTrue(reason.contains("between 11 and 26"))
        }
    }
    
    func testADCChannelMapping() {
        // Test ADC channel mapping for all chip families
        
        // ESP32-C6: GPIO0-7 → ADC1_CHANNEL_0-7
        for pin in 0 ... 7 {
            XCTAssertNoThrow(try BoardCapabilities.adcChannelForPin(pin, board: "esp32-c6-devkitc-1"))
            do {
                let channel = try BoardCapabilities.adcChannelForPin(pin, board: "esp32-c6-devkitc-1")
                XCTAssertEqual(channel, pin)
            } catch {
                XCTFail("Unexpected error for ESP32-C6 GPIO\(pin): \(error)")
            }
        }
        // GPIO8+ should throw error for C6
        XCTAssertThrowsError(try BoardCapabilities.adcChannelForPin(8, board: "esp32-c6-devkitc-1"))
        
        // ESP32-C3: GPIO0-4 → ADC1_CHANNEL_0-4
        for pin in 0 ... 4 {
            XCTAssertNoThrow(try BoardCapabilities.adcChannelForPin(pin, board: "esp32-c3-devkitm-1"))
            do {
                let channel = try BoardCapabilities.adcChannelForPin(pin, board: "esp32-c3-devkitm-1")
                XCTAssertEqual(channel, pin)
            } catch {
                XCTFail("Unexpected error for ESP32-C3 GPIO\(pin): \(error)")
            }
        }
        // GPIO5+ should throw error for C3
        XCTAssertThrowsError(try BoardCapabilities.adcChannelForPin(5, board: "esp32-c3-devkitm-1"))
        
        // ESP32-H2: GPIO0-4 → ADC1_CHANNEL_0-4
        for pin in 0 ... 4 {
            XCTAssertNoThrow(try BoardCapabilities.adcChannelForPin(pin, board: "esp32-h2-devkitc-1"))
            do {
                let channel = try BoardCapabilities.adcChannelForPin(pin, board: "esp32-h2-devkitc-1")
                XCTAssertEqual(channel, pin)
            } catch {
                XCTFail("Unexpected error for ESP32-H2 GPIO\(pin): \(error)")
            }
        }
        // GPIO5+ should throw error for H2
        XCTAssertThrowsError(try BoardCapabilities.adcChannelForPin(5, board: "esp32-h2-devkitc-1"))
        
        // ESP32-P4: GPIO0-7 → ADC1_CHANNEL_0-7
        for pin in 0 ... 7 {
            XCTAssertNoThrow(try BoardCapabilities.adcChannelForPin(pin, board: "esp32-p4-function-ev-board"))
            do {
                let channel = try BoardCapabilities.adcChannelForPin(pin, board: "esp32-p4-function-ev-board")
                XCTAssertEqual(channel, pin)
            } catch {
                XCTFail("Unexpected error for ESP32-P4 GPIO\(pin): \(error)")
            }
        }
        // GPIO8+ should throw error for P4
        XCTAssertThrowsError(try BoardCapabilities.adcChannelForPin(8, board: "esp32-p4-function-ev-board"))
        
        // Test with unsupported board
        XCTAssertThrowsError(try BoardCapabilities.adcChannelForPin(0, board: "unsupported-board"))
    }
}