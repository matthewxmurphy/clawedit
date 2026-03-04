// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClawEdit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ClawEdit",
            targets: ["ClawEdit"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClawEdit",
            path: "Sources/ClawEdit",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
