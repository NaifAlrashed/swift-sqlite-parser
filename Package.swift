// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-sqlite-parser",
    products: [
        .library(
            name: "SQLiteParser",
            targets: ["SQLiteParser"]
        ),
    ],
    targets: [
        .target(name: "SQLiteParser"),
        .testTarget(
            name: "SQLiteParserTests",
            dependencies: ["SQLiteParser"]
        ),
    ]
)
