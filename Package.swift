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
        .package(url: "https://github.com/UbiqueInnovation/swift-sodium.git", .branch("feature/full-libsodium")),
        .package(url: "https://github.com/apple/swift-protobuf.git", .revision("1.13.0")),
    ],
    targets: [
        .target(
            name: "N2StepSDK",
            dependencies: ["Sodium", "Clibsodium", "SwiftProtobuf"]
        ),
        .testTarget(
            name: "N2StepSDKTests",
            dependencies: ["N2StepSDK"]
        ),
    ]
)
