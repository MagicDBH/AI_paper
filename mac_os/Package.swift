// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AI_Paper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AI_Paper", targets: ["AI_Paper"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AI_Paper",
            path: "AI_Paper"
        ),
        .testTarget(
            name: "AI_PaperTests",
            dependencies: [],
            path: "AI_PaperTests"
        )
    ]
)
