// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SplitWallet",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SplitWallet",
            targets: ["SplitWallet"]
        ),
    ],
    targets: [
        .target(
            name: "SplitWallet",
            path: "SplitWallet",
            exclude: ["Tests"]
        ),
        .testTarget(
            name: "SplitWalletTests",
            dependencies: ["SplitWallet"],
            path: "SplitWallet/Tests/SplitWalletTests"
        )
    ]
)
