// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Woodpecker",
    products: [
        .library(name: "Woodpecker", targets: ["Woodpecker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/glessard/swift-atomics", from: "4.0.0"),
    ],
    targets: [
        .target(name: "Woodpecker", dependencies: ["Atomics"]),
        .testTarget(name: "WoodpeckerTests", dependencies: ["Woodpecker"]),
    ]
)
