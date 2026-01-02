// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPAIVE",
    platforms: [
        .iOS(.v16), // Targeting iOS 16.0+ as iOS 26.0 is not yet available
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SPAIVE",
            targets: ["SPAIVE"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SPAIVE",
            resources: [
                // 仅使用 mlmodelc 即可，避免重复资源名称冲突
                .copy("Resources/yolo11n.mlmodelc"),
                // .copy("Resources/yolo11n.mlpackage") // 暂时注释掉，避免与 mlmodelc 冲突或产生冗余
            ]
        ),
        .testTarget(
            name: "SPAIVETests",
            dependencies: ["SPAIVE"]),
    ]
)
