// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "N2StepSDK",
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(
            name: "N2StepSDK",
            targets: ["N2StepSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jedisct1/swift-sodium.git", .revision("0.9.0")),
        .package(url: "https://github.com/apple/swift-protobuf.git", .revision("1.13.0")),
    ],
    targets: [
        .target(
            name: "N2StepSDK",
            dependencies: ["Sodium", "SwiftProtobuf"]
        ),
        .testTarget(
            name: "N2StepSDKTests",
            dependencies: ["N2StepSDK"]
        ),
    ]
)
