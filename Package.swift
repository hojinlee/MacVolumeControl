// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacVolumeControl",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacVolumeControl",
            targets: ["MacVolumeControl"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacVolumeControl"
        )
    ]
)
