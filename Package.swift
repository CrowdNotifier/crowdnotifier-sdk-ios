// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CrowdNotifierSDK",
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(
            name: "CrowdNotifierSDK",
            targets: ["CrowdNotifierSDK"]
        ),
        .library(
            name: "Clibsodium",
            targets: ["Clibsodium"]
        ),
    ],
    dependencies: [
        .package(
            name: "SwiftProtobuf",
            url: "https://github.com/apple/swift-protobuf.git",
            .revision("1.13.0")
        ),
    ],
    targets: [
        .target(
            name: "CrowdNotifierSDK",
            dependencies: ["SwiftProtobuf", "Clibsodium"],
            exclude: ["libsodium", "Info.plist"]
        ),
        .binaryTarget(
            name: "Clibsodium",
            path: "Clibsodium.xcframework"
        ),
        .testTarget(
            name: "CrowdNotifierSDKTests",
            dependencies: ["CrowdNotifierSDK"]
        ),
    ]
)
