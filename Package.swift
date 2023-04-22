// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "IngressDroneExplorer",
    products: [
        .executable(name: "ingress-drone-explorer", targets: [ "ingress-drone-explorer" ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.2")),
    ],
    targets: [
        .executableTarget(
            name: "ingress-drone-explorer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
