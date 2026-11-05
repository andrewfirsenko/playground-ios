// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureToggles",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "FeatureToggles", targets: ["FeatureToggles"])
    ],
    targets: [
        .target(name: "FeatureToggles"),
        .testTarget(
            name: "FeatureTogglesTests",
            dependencies: ["FeatureToggles"],
            swiftSettings: [
                // .define("PART1"),
                // .define("PART2"),
                // .define("PART3"),
                // .define("BONUS"),
            ]
        )
    ]
)
