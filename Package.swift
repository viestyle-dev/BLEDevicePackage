// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BLEDevicePackage",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "BLEDevicePackage",
            targets: ["BLEDevicePackage"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BLEDevicePackage",
            dependencies: []),
        .testTarget(
            name: "BLEDevicePackageTests",
            dependencies: ["BLEDevicePackage"]),
    ]
)
