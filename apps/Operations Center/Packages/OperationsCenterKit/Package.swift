// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OperationsCenterKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OperationsCenterKit",
            targets: ["OperationsCenterKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OperationsCenterKit",
            dependencies: []
        )
    ]
)
