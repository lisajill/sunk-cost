// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TheMoneyPit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TheMoneyPit", targets: ["TheMoneyPit"])
    ],
    targets: [
        .target(name: "TheMoneyPitCore"),
        .executableTarget(
            name: "TheMoneyPit",
            dependencies: ["TheMoneyPitCore"]
        ),
        .testTarget(
            name: "TheMoneyPitCoreTests",
            dependencies: ["TheMoneyPitCore"]
        )
    ]
)
