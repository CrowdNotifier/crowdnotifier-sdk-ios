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
        .library(name: "CrowdNotifierBaseSDK",
                 targets: ["CrowdNotifierBaseSDK"]
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
        .package(
            name: "HKDF",
            url: "https://github.com/Bouke/HKDF.git",
            .exact("3.1.0")
        ),
    ],
    targets: [
        .target(
            name: "CrowdNotifierSDK",
            dependencies: ["CrowdNotifierBaseSDK", "SwiftProtobuf", "HKDF", "Clibsodium", "libmcl"],
            exclude: ["libsodium", "Info.plist"],
            linkerSettings: [ .linkedLibrary("stdc++") ]
        ),
        .target(name: "CrowdNotifierBaseSDK",
            dependencies: ["SwiftProtobuf", "HKDF"]
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
            dependencies: ["CrowdNotifierSDK", "CrowdNotifierBaseSDK"]
        ),
    ]
)
