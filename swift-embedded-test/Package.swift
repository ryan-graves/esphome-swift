// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftEmbeddedESP32",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "ESP32Firmware",
            targets: ["ESP32Firmware"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ESP32Firmware",
            dependencies: ["ESP32Hardware", "SwiftEmbeddedCore"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-Xfrontend", "-function-sections",
                    "-Xfrontend", "-data-sections",
                    "-Xfrontend", "-disable-stack-protector"
                ])
            ]
        ),
        .target(
            name: "ESP32Hardware",
            swiftSettings: [
                .enableExperimentalFeature("Embedded")
            ]
        ),
        .target(
            name: "SwiftEmbeddedCore",
            swiftSettings: [
                .enableExperimentalFeature("Embedded")
            ]
        )
    ]
)