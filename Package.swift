// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineStarscream",
    platforms: [
        .iOS(.v13), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "CombineStarscream",
            targets: ["CombineStarscream"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.1"),
    ],
    targets: [
        .target(
            name: "CombineStarscream",
            dependencies: ["Starscream"]),
        .testTarget(
            name: "CombineStarscreamTests",
            dependencies: ["CombineStarscream", "Starscream"]),
    ]
)
