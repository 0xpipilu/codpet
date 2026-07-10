// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodpetPersonal",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CodpetPersonal",
            targets: ["CodpetPersonal"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CodpetPersonal",
            path: "Sources"
        )
    ]
)
