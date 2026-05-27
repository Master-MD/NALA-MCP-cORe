// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "NALA-MCP-cORe",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "NALAMCPcOReCore",
            targets: ["NALAMCPcOReCore"]
        ),
        .executable(
            name: "NALA-MCP-cORe",
            targets: ["NALAMCPcOReApp"]
        ),
        .executable(
            name: "nala-mcp-core-helper",
            targets: ["NALAMCPcOReHelper"]
        )
    ],
    targets: [
        .target(
            name: "CSQLite",
            publicHeadersPath: "include"
        ),
        .target(
            name: "NALAMCPcOReCore",
            dependencies: ["CSQLite"],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .executableTarget(
            name: "NALAMCPcOReApp",
            dependencies: ["NALAMCPcOReCore"],
            resources: [
                .copy("Resources/AppIcon.png"),
                .copy("Resources/Help")
            ]
        ),
        .executableTarget(
            name: "NALAMCPcOReHelper",
            dependencies: ["NALAMCPcOReCore"]
        ),
        .testTarget(
            name: "NALAMCPcOReCoreTests",
            dependencies: ["NALAMCPcOReCore"]
        )
    ]
)
