// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorWechat",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapgoCapacitorWechat",
            targets: ["CapacitorWechatPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "CapacitorWechatPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/CapacitorWechatPlugin"),
        .testTarget(
            name: "CapacitorWechatPluginTests",
            dependencies: ["CapacitorWechatPlugin"],
            path: "ios/Tests/CapacitorWechatPluginTests")
    ]
)
