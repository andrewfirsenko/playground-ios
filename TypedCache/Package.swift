// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TypedCache",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "TypedCache", targets: ["TypedCache"])
    ],
    targets: [
        .target(name: "TypedCache"),
        .testTarget(
            name: "TypedCacheTests",
            dependencies: ["TypedCache"],
            swiftSettings: [
                 .define("PART1"),
                 .define("PART2"),
                 .define("PART3"),
                // .define("BONUS"),
            ]
        )
    ]
)
