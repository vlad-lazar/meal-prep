// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MealPrepCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [.library(name: "MealPrepCore", targets: ["MealPrepCore"])],
    targets: [
        .target(name: "MealPrepCore"),
        .testTarget(name: "MealPrepCoreTests", dependencies: ["MealPrepCore"], resources: [.copy("Fixtures")]),
    ]
)
