// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MealPrepCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "MealPrepCore", targets: ["MealPrepCore"]),
        .executable(name: "mealprep-cli", targets: ["mealprep-cli"]),
    ],
    targets: [
        .target(name: "MealPrepCore", resources: [.process("Resources")]),
        .executableTarget(name: "mealprep-cli", dependencies: ["MealPrepCore"]),
        .testTarget(name: "MealPrepCoreTests", dependencies: ["MealPrepCore"], resources: [.copy("Fixtures")]),
    ]
)
