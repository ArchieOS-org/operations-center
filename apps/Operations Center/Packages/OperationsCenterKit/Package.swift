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
    dependencies: [
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "OperationsCenterKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        )
    ]
)
