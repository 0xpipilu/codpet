// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodpetHybrid",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CodpetHybrid",
            targets: ["CodpetHybrid"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CodpetHybrid",
            path: "Sources"
        )
    ]
)
