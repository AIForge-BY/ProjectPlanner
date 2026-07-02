// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ProjectPlanner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ProjectPlanner", targets: ["ProjectPlanner"])
    ],
    targets: [
        .executableTarget(name: "ProjectPlanner"),
        .testTarget(
            name: "ProjectPlannerTests",
            dependencies: ["ProjectPlanner"]
        )
    ]
)
