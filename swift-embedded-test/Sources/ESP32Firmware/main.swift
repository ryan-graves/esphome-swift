// ESP32 Firmware Main Entry Point - Swift Embedded

import ESP32Hardware
import SwiftEmbeddedCore

/// Main firmware application
@main
struct ESP32App {
    static func main() {
        print("ESPHome Swift - Temperature Sensor")
        print("Board: ESP32-C6")
        print("Framework: Swift Embedded")
        
        // Create DHT sensor on GPIO4
        var dhtSensor = DHTSensor(
            id: "living_room_sensor",
            name: "Living Room",
            pin: .pin4,
            model: .dht22
        )
        
        // Create temperature and humidity sensor views
        var tempSensor = DHTTemperatureSensor(dhtSensor: dhtSensor)
        var humiditySensor = DHTHumiditySensor(dhtSensor: dhtSensor)
        
        // Setup phase
        do {
            print("Initializing components...")
            try dhtSensor.setup()
            print("Setup complete!")
        } catch {
            print("Setup failed: \(error)")
            // In real implementation: esp_restart()
            return
        }
        
        // Main loop
        print("Entering main loop...")
        while true {
            do {
                // Update sensor
                try dhtSensor.loop()
                
                // Read and report values
                if let temp = try tempSensor.readValue() {
                    print("Temperature: \(temp)°C")
                    tempSensor.reportState(temp)
                }
                
                if let humidity = try humiditySensor.readValue() {
                    print("Humidity: \(humidity)%")
                    humiditySensor.reportState(humidity)
                }
                
                // Delay to prevent watchdog timeout
                // In real implementation: vTaskDelay(pdMS_TO_TICKS(100))
                
            } catch {
                print("Loop error: \(error)")
            }
        }
    }
}