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
        ),
        // Narrow coverage for the app target: only the non-UI logic that
        // has actually had bugs -- the storage-folder switch state machine
        // and AppStore's save/rollback/apply plumbing. Not views.
        .testTarget(
            name: "SunkCostTests",
            dependencies: ["SunkCost"]
        )
    ]
)
