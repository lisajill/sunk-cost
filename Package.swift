// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SunkCost",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SunkCost", targets: ["SunkCost"])
    ],
    targets: [
        .target(name: "SunkCostCore"),
        .executableTarget(
            name: "SunkCost",
            dependencies: ["SunkCostCore"]
        ),
        .testTarget(
            name: "SunkCostCoreTests",
            dependencies: ["SunkCostCore"]
        )
    ]
)
