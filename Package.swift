// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "IngressDroneExplorer",
    products: [
        .executable(name: "ingress-drone-explorer", targets: [ "ingress-drone-explorer" ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ingress-drone-explorer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            linkerSettings: [
                .linkedLibrary("c -static", .when(platforms: [ .linux ]))
            ]
        ),
    ]
)
