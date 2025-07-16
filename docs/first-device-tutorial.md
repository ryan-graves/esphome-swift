---
layout: default
title: Build Your First Smart Home Device
---

# Build Your First Smart Home Device with ESPHome Swift

Welcome! Today we're going to build something amazing together – your very first smart home device. By the end of this tutorial, you'll have a temperature sensor that talks to your home automation system, and more importantly, you'll understand how it all works.

## What We're Building

We're creating a smart temperature and humidity sensor that:
- Measures the temperature and humidity in any room
- Connects to your WiFi network
- Works with **all major smart home platforms** (Apple Home, Google Home, Alexa, Samsung SmartThings, Home Assistant)
- Uses Matter protocol for universal compatibility
- Can be built in about an hour
- Costs less than $25 total

The best part? No programming experience required! We'll walk through every single step together.

## Why Build Your Own?

Sure, you could buy a smart sensor, but building your own means:
- **Universal compatibility** - works with ANY smart home platform
- You learn how smart home devices actually work
- You can customize it exactly how you want
- **Platform flexibility** - switch platforms if needed (requires factory reset)
- It's more fun (trust us!)
- You join a community of makers and tinkerers

## Shopping List

Here's everything you'll need. We've included links to make shopping easy:

**⚠️ Note**: External shopping links may become outdated over time. Please verify product availability and specifications before purchasing.

### Required Items (Total: ~$20-25)

**1. ESP32-C6-DevKitC-1 Development Board** ($10-15)
- The brain of your project
- Has WiFi, Bluetooth, and Matter support built-in
- Get it from: [Amazon](https://www.amazon.com/dp/B0BRMSDR4R) | [Adafruit](https://www.adafruit.com/product/5672) | [DFRobot](https://www.dfrobot.com/product-2692.html)

**2. DHT22 Temperature & Humidity Sensor Kit** ($5-10)
- Measures temperature and humidity
- Kit includes the pull-up resistor you need
- Get it from: [Amazon](https://www.amazon.com/s?k=dht22+sensor+kit) | [Adafruit](https://www.adafruit.com/product/385)

**3. Breadboard** ($5)
- Half-size (400 tie points) is perfect
- No soldering required!
- Get it from: [Amazon](https://www.amazon.com/s?k=half+size+breadboard) | [Adafruit](https://www.adafruit.com/product/64)

**4. Jumper Wires** ($5)
- Get a variety pack with male-to-male and male-to-female
- Different colors help you stay organized
- Get it from: [Amazon](https://www.amazon.com/s?k=jumper+wires+kit) | [Adafruit](https://www.adafruit.com/product/758)

**5. USB-C Cable**
- You probably already have one
- Needs to support data (not just charging)

### Optional Enhancements

**Status LED Kit** ($5)
- Any color LED + 220Ω resistor
- Adds a visual indicator when your sensor takes readings
- Get it from: [Amazon](https://www.amazon.com/s?k=led+resistor+kit) | [Adafruit](https://www.adafruit.com/product/4203)

**Small Project Box** ($5-10)
- For when you want to mount it permanently
- Get one that fits a half-size breadboard
- Get it from: [Amazon](https://www.amazon.com/s?k=breadboard+project+box)

## Part 1: Setting Up Your Computer

Before we can program our device, we need to set up the software on your computer. Don't worry – this is the most technical part, and we'll walk through it step by step.

### Step 1: Install Swift

Swift is the programming language that powers ESPHome Swift (though you won't need to write any code!).

**On macOS:**
1. Swift comes pre-installed on most Macs
2. Open Terminal and type: `swift --version`
3. If you see a version number (5.9 or higher), you're good!
4. If not, download from [swift.org](https://swift.org/download/)

**On Linux:**
1. Visit [swift.org/download](https://swift.org/download/)
2. Follow the instructions for your Linux distribution
3. Verify with: `swift --version`

**On Windows:**
1. Install WSL2 (Windows Subsystem for Linux) first
2. Then follow the Linux instructions above
3. All your work will happen in the WSL2 terminal

### Step 2: Install ESP-IDF

ESP-IDF is what actually builds the code for your ESP32 board.

```bash
# Create a directory for ESP tools
mkdir -p ~/esp
cd ~/esp

# Download ESP-IDF (this takes a few minutes)
git clone -b v5.3 --recursive https://github.com/espressif/esp-idf.git

# Install it (this also takes a few minutes)
cd esp-idf
./install.sh esp32c6

# Load the ESP-IDF environment
. ./export.sh
```

**Success Check**: After running `. ./export.sh`, you should see a message about ESP-IDF being ready.

### Step 3: Install ESPHome Swift

Now for the star of the show:

```bash
# Clone the repository
git clone https://github.com/ryan-graves/esphome-swift.git
cd esphome-swift

# Build it
swift build -c release

# Install it
sudo cp .build/release/esphome-swift /usr/local/bin/

# Verify it works
esphome-swift --version
```

**Success Check**: You should see a version number when you run the last command.

## Part 2: Your First Connection

Let's make sure your board works before we build anything!

### Step 1: Plug In Your Board

1. Connect your ESP32-C6-DevKitC-1 to your computer with the USB-C cable
2. You should see a small LED light up on the board

### Step 2: Find Your Board

**On macOS:**
```bash
ls /dev/tty.usb*
```

**On Linux:**
```bash
ls /dev/ttyUSB*
```

You should see something like `/dev/ttyUSB0` or `/dev/tty.usbserial-0001`. Write this down – it's your board's address!

### Step 3: Quick Test

Let's create a simple "Hello World" to make sure everything works:

```bash
# Create a new project
esphome-swift new my-first-device
cd my-first-device

# This created a basic configuration file
cat my-first-device.yaml
```

You should see a basic YAML configuration. We'll customize this soon!

## Part 3: Building the Circuit

Now for the fun part – let's wire up our temperature sensor!

### Understanding the Breadboard

A breadboard lets you connect components without soldering:
- The rows (numbered 1-30) are connected horizontally
- The power rails (+ and -) run vertically on the sides
- The gap in the middle separates the two halves

### Wiring Your Temperature Sensor

Your DHT22 sensor has 4 pins (from left to right when facing the grid):
1. **VCC** (Power) - Connects to 3.3V
2. **DATA** (Signal) - Connects to GPIO4
3. **NC** (Not Connected) - Skip this one
4. **GND** (Ground) - Connects to GND

**Step-by-Step Wiring:**

1. Insert your ESP32 board into the breadboard (it should straddle the center gap)

2. Insert the DHT22 sensor a few rows away from the ESP32

3. Make these connections with jumper wires:
   - DHT22 Pin 1 (VCC) → ESP32 3V3 pin
   - DHT22 Pin 2 (DATA) → ESP32 GPIO4 pin  
   - DHT22 Pin 4 (GND) → ESP32 GND pin
   - Leave Pin 3 unconnected

4. If your kit included a resistor, connect it between DHT22 pins 1 and 2

**Double-Check**: Make sure:
- All connections are firm
- You're using 3.3V, not 5V
- The sensor is facing the right way (grid side forward)

## Part 4: Writing Your Configuration

Time to tell ESPHome Swift what we've built!

### Step 1: Generate Your Device Credentials

Before writing the configuration, let's generate unique Matter credentials for your device. This ensures your device has its own secure "identity" on the Matter network:

```bash
esphome-swift generate-credentials
```

You'll see output like this:

```
Matter Device Credentials
========================
Discriminator: 2847
Passcode: 73829502
Manual Pairing Code: 84739-264851
QR Code: MT:Y.K90HRX00KA0648G00

SECURITY WARNING: Store these credentials securely.
Each device must have unique credentials.
```

**Copy these values** - you'll need the discriminator and passcode for the next step!

**Why do this?** These credentials are like your device's unique "phone number" and "password" on the Matter network. Using unique values prevents conflicts with other devices and ensures secure commissioning.

### Step 2: Create Your Configuration

Edit `my-first-device.yaml`:

```yaml
# Device Information
esphome_swift:
  name: temperature_sensor
  friendly_name: "My Temperature Sensor"

# Board Configuration
esp32:
  board: esp32-c6-devkitc-1
  framework:
    type: esp-idf

# WiFi Configuration
wifi:
  ssid: "YourWiFiName"
  password: "YourWiFiPassword"
  
  # Fallback hotspot (creates access point if wifi fails)
  ap:
    ssid: "Temperature-Sensor"
    password: "12345678"

# Enable logging so we can see what's happening
logger:
  level: INFO

# Matter configuration for universal smart home compatibility
matter:
  enabled: true
  device_type: temperature_sensor
  vendor_id: 0xFFF1
  product_id: 0x8001
  
  # Commissioning setup - your device's "address" in Matter
  # Use the values from your generated credentials above!
  commissioning:
    discriminator: 2847  # Replace with YOUR generated discriminator
    passcode: 73829502   # Replace with YOUR generated passcode
  
  # Use WiFi transport for connectivity
  network:
    transport: wifi
    ipv6_enabled: true
    mdns:
      enabled: true
      hostname: temperature-sensor  # Change this for multiple devices to avoid conflicts

# Enable Over-The-Air updates
ota:
  - platform: esphome_swift

# Our Temperature Sensor
sensor:
  - platform: dht
    pin:
      number: GPIO4
    model: DHT22
    temperature:
      name: "Room Temperature"
      id: room_temp
      # Matter will automatically expose this as a temperature measurement
    humidity:
      name: "Room Humidity"
      id: room_humidity
      # Available for future humidity sensor device types
    update_interval: 60s
```

**Building Multiple Devices?** If you plan to build more than one sensor:
- **Important**: Run `esphome-swift generate-credentials` again to get unique discriminator and passcode values for each device - this prevents commissioning conflicts and ensures security
- Change the `hostname` to something unique like `kitchen-sensor` or `bedroom-sensor` to avoid network conflicts

### Step 3: Create a Secrets File

For security, let's put sensitive info in a separate file. Create `secrets.yaml`:

```yaml
wifi_ssid: "YourWiFiName"
wifi_password: "YourWiFiPassword"
```

Update your main configuration to use these secrets:

```yaml
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
```

**What about the Matter credentials?** The discriminator and passcode serve different purposes:
- **Discriminator**: Like your device's "phone number" - helps platforms find your device during commissioning  
- **Passcode**: A security credential used for secure commissioning authentication - this should be treated as sensitive information

**Why generate them?** Each device needs unique credentials to prevent commissioning conflicts and ensure security. The passcode must be randomized for each device to prevent unauthorized access. The credential generator uses cryptographically secure random number generation that complies with CSA Matter Core Specification requirements.

**Need multiple devices?** Run `esphome-swift generate-credentials --count 5 --format yaml` to generate credentials for multiple devices at once!

### Step 4: Validate Your Configuration

Let's make sure everything looks good:

```bash
esphome-swift validate my-first-device.yaml
```

**Success Check**: You should see "Configuration is valid!" If you see errors, double-check your YAML formatting (indentation matters!).

## Part 5: Building and Flashing

Almost there! Let's turn your configuration into actual firmware.

### Step 1: Set Up the Environment

```bash
# Make sure ESP-IDF is loaded
. ~/esp/esp-idf/export.sh
```

### Step 2: Build the Firmware

```bash
esphome-swift build my-first-device.yaml
```

This will take a few minutes the first time. You'll see lots of output – that's normal!

**Success Check**: Look for "Build complete" at the end.

### Step 3: Flash to Your Board

Remember that port we found earlier? Time to use it:

```bash
esphome-swift flash build/temperature_sensor --port /dev/ttyUSB0
```

(Replace `/dev/ttyUSB0` with your actual port)

The board's LED might flicker during upload – that's normal!

**Success Check**: You should see "Flash complete" when done.

## Part 6: Monitoring Your Device

Let's see your sensor in action!

```bash
esphome-swift monitor build/temperature_sensor --port /dev/ttyUSB0
```

You should see:
- Boot messages
- WiFi connection status  
- Temperature and humidity readings every 60 seconds

Example output:
```
[I] WiFi: Connected to YourWiFiName
[I] IP Address: 192.168.1.123
[I] Room Temperature: 72.5°F
[I] Room Humidity: 45.2%
```

**Tip**: Press Ctrl+C to stop monitoring.

## Part 7: Smart Home Integration

Your sensor uses Matter, the universal smart home protocol! This means it works with **all major platforms** - Apple Home, Google Home, Amazon Alexa, Samsung SmartThings, and Home Assistant.

### Step 1: Find Your QR Code

When your device boots up, look for this in the serial monitor:

```
========== MATTER COMMISSIONING INFO ==========
QR Code: MT:Y.K90HRX00KA0648G00
Manual Pairing Code: 12111-128008
Discriminator: 2847
Setup PIN: 73829502
===============================================
```

**Note**: Your output will show the **exact credentials you generated** in Step 1 of Part 4. The QR code and manual pairing code are automatically calculated from your unique discriminator and passcode values.

**Important**: Copy or screenshot this information - you'll need it for setup!

### Step 2: Choose Your Smart Home Platform

Pick your platform and follow the instructions:

#### Apple HomeKit (iPhone/iPad/Mac)
1. Open the **Home** app on your iPhone
2. Tap **+** → **Add or Scan Accessory**
3. Point your camera at the QR code shown in the serial monitor
4. Follow the setup prompts
5. **Success**: Your sensor appears in Apple Home!

#### Google Home
1. Open the **Google Home** app
2. Tap **+** → **Set up device** → **Works with Google**
3. Look for **Matter** devices
4. Tap **Scan QR code** and scan the code from serial monitor
5. **Success**: "Temperature Sensor" appears in Google Home!

#### Amazon Alexa
1. Open the **Alexa** app
2. Go to **Devices** → **+** → **Add Device**
3. Select **Other** → **Matter**
4. Choose **Scan QR code** and scan the code
5. **Success**: Your sensor is now available via Alexa!

#### Samsung SmartThings
1. Open the **SmartThings** app
2. Tap **+** → **Scan QR code**
3. Scan the Matter QR code from serial monitor
4. Follow setup prompts
5. **Success**: Sensor added to SmartThings!

### Step 3: Manual Setup (If QR Code Doesn't Work)

If QR scanning fails, use the manual pairing code:

1. In your smart home app, look for **"Enter setup code manually"** or **"Can't scan?"**
2. Enter the manual pairing code shown in your serial monitor output (e.g., **12111-128008**)
3. Complete the setup process

### What You Can Do Now

🎉 **Congratulations!** Your sensor now works with your chosen platform. You can:

- **View temperature/humidity** in your smart home app
- **Create automations** (turn on heat when temp drops)
- **Get notifications** about readings
- **Control from voice assistants** ("Hey Google, what's the temperature?")
- **Switch platforms later** - Matter devices can be reset and moved between ecosystems if needed

### Optional: Home Assistant Integration

If you use Home Assistant, you can add your Matter device there too! Since your device uses Matter, it's **compatible with both Matter and Home Assistant APIs**.

#### Method 1: Matter Integration (Recommended)
1. In Home Assistant, go to **Settings** → **Devices & Services**
2. Click **+ Add Integration**
3. Search for **Matter (BETA)**
4. Use the QR code or manual pairing code from your device
5. Your sensor appears with full Matter compatibility!

#### Method 2: Direct API (Advanced)
If you prefer the ESPHome integration:

1. Add this to your device configuration (after the Matter section):
```yaml
# Optional: Enable Home Assistant API (in addition to Matter)
api:
  encryption:
    key: !secret api_encryption_key
```

2. Add the encryption key to your `secrets.yaml`:
```yaml
api_encryption_key: "abc123def456ghi789jkl012mno34567"
```

3. Flash the updated firmware and follow the ESPHome integration steps in Home Assistant.

**Pro Tip**: We recommend the Matter integration as it's more future-proof and standardized!

## Optional Enhancement: Adding a Status LED

If you bought the optional LED, let's add a visual indicator!

### Additional Wiring

1. Insert the LED into the breadboard
   - Longer leg (positive) in one row
   - Shorter leg (negative) in another row

2. Connect with jumper wires:
   - LED positive → 220Ω resistor → ESP32 GPIO5
   - LED negative → ESP32 GND

### Additional Configuration

Add this to your YAML:

```yaml
# Status LED
output:
  - platform: gpio
    pin: GPIO5
    id: status_led

# Blink when taking readings
interval:
  - interval: 60s
    then:
      - output.turn_on: status_led
      - delay: 100ms
      - output.turn_off: status_led
```

Now your LED will blink every time it takes a reading!

## Optional Enhancement: Project Box Installation

Ready to make it permanent? Here's how to install in a project box:

1. **Test everything** one more time on the breadboard

2. **Plan your layout** - arrange components for easy access to the USB port

3. **Secure the breadboard** with double-sided tape or velcro

4. **Drill ventilation holes** for the temperature sensor

5. **Label it** - add a label with the device name and WiFi info

**Tips**:
- Keep wires short and tidy
- Make sure the sensor has airflow
- Consider adding feet to prevent scratching

## Troubleshooting

Don't worry if something doesn't work right away – troubleshooting is part of the journey!

### WiFi Won't Connect
- Double-check your WiFi name and password in `secrets.yaml`
- Make sure you're using a 2.4GHz network
- Try moving closer to your router
- Use the fallback AP mode to reconfigure

### No Sensor Readings
- Check all your wire connections
- Make sure you're using GPIO4 (or update the config)
- Try unplugging and reconnecting the USB cable
- Verify the sensor is facing the right direction

### Upload Fails
- Make sure no other program is using the serial port
- Try a different USB cable (some are charge-only)
- Hold the BOOT button while the upload starts
- Use a slower baud rate: add `--baud-rate 115200`

### Can't Find the Device Port
- Unplug and replug the USB cable
- Install CH340 drivers if needed (search for your OS)
- Try a different USB port on your computer

## What's Next?

Congratulations! You've built your first smart home device! Here are some ideas for what to do next:

### Easy Projects
- Add more sensors to the same board
- Create multiple sensors for different rooms
- Add a display to show readings locally
- Build a plant moisture monitor

### Learn More
- Explore the [Component Library](components.html)
- Join the ESPHome Swift community
- Check out the [ESPHome forums](https://community.home-assistant.io/c/esphome)
- Share your project with others!

### Advanced Ideas
- Build a weather station with multiple sensors
- Create automated alerts based on temperature
- Add presence detection with a PIR sensor
- Build a air quality monitor

## Final Thoughts

You did it! You've not only built a smart home device, but you've learned:
- How microcontrollers work
- Basic electronics and wiring
- YAML configuration
- How IoT devices communicate

Most importantly, you've joined a community of makers who believe in open source, local control, and the joy of building things yourself.

Welcome to the world of DIY smart home devices – we can't wait to see what you build next!

---

**Need Help?** The ESPHome Swift community is here for you. Don't hesitate to ask questions – we all started as beginners!