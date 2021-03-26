// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CrowdNotifierSDK",
    platforms: [
        .iOS("10.0"),
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
        .library(
            name: "libmcl",
            targets: ["libmcl"]
        ),
    ],
    dependencies: [
        .package(
            name: "SwiftProtobuf",
            url: "https://github.com/apple/swift-protobuf.git",
            .exact("1.13.0")
        ),
    ],
    targets: [
        .target(
            name: "CrowdNotifierSDK",
            dependencies: ["SwiftProtobuf", "Clibsodium", "libmcl"],
            exclude: ["libsodium", "Info.plist"]
        ),
        .binaryTarget(
            name: "Clibsodium",
            path: "Clibsodium.xcframework"
        ),
        .binaryTarget(
            name: "libmcl",
            path: "libmcl.xcframework"
        ),
        .testTarget(
            name: "CrowdNotifierSDKTests",
            dependencies: ["CrowdNotifierSDK"]
        ),
    ]
)
