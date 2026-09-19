// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SplitFlap",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SplitFlap", targets: ["SplitFlap"])
    ],
    targets: [
        .target(name: "SplitFlap"),
        .testTarget(name: "SplitFlapTests", dependencies: ["SplitFlap"])
    ]
)
