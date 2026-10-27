// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OpalKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "OpalCore", targets: ["OpalCore"]),
        .library(name: "OpalDesign", targets: ["OpalDesign"])
    ],
    targets: [
        .target(name: "OpalDesign"),
        .target(name: "OpalCore"),
        .testTarget(
            name: "OpalCoreTests",
            dependencies: ["OpalCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
