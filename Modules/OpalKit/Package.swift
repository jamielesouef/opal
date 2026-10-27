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
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.10.0")
    ],
    targets: [
        .target(name: "OpalDesign"),
        .target(name: "OpalCore", dependencies: [.product(name: "GRDB", package: "GRDB.swift")]),
        .testTarget(
            name: "OpalCoreTests",
            dependencies: ["OpalCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
