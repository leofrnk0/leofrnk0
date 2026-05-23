// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TriWorkouts",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "TriWorkouts",
            path: "Sources/TriWorkouts",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
