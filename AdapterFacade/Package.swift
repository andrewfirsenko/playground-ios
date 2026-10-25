// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AdapterFacade",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "AdapterFacade", targets: ["AdapterFacade"])
    ],
    targets: [
        .target(name: "AdapterFacade"),
        .testTarget(name: "AdapterFacadeTests", dependencies: ["AdapterFacade"])
    ]
)
