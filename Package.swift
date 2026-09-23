// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IgniteTalkPDF",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "IgniteTalkCore", targets: ["IgniteTalkCore"]),
        .executable(name: "IgniteTalkPDF", targets: ["IgniteTalkPDF"]),
        .executable(name: "IgniteTalkCoreChecks", targets: ["IgniteTalkCoreChecks"])
    ],
    targets: [
        .target(
            name: "IgniteTalkCore",
            path: "IgniteTalkPDF/Core"
        ),
        .executableTarget(
            name: "IgniteTalkPDF",
            dependencies: ["IgniteTalkCore"],
            path: "IgniteTalkPDF/App"
        ),
        .executableTarget(
            name: "IgniteTalkCoreChecks",
            dependencies: ["IgniteTalkCore"],
            path: "Validation"
        ),
        .testTarget(
            name: "IgniteTalkCoreTests",
            dependencies: ["IgniteTalkCore"],
            path: "IgniteTalkPDFTests"
        )
    ]
)
