// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-sqlite-parser",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "SQLiteParser",
            targets: ["SQLiteParser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
    ],
    targets: [
        .target(
            name: "SQLiteParser",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
            ]
        ),
        .testTarget(
            name: "SQLiteParserTests",
            dependencies: ["SQLiteParser"]
        ),
    ]
)
