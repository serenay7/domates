// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Domates",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Domates",
            path: "Sources/Domates"
        )
    ]
)
