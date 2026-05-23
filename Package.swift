// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TriWorkouts",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TriWorkouts",
            path: "Sources/TriWorkouts",
            resources: [
                .process("Resources"),
                .copy("Info.plist")
            ]
        )
    ]
)
