import PackageDescription

let package = Package(
    name: "VimChannelKit",
    targets: [
        Target(name: "LoggerAPI", dependencies: []),
        Target(name: "Channel", dependencies: ["LoggerAPI"]),
        Target(name: "example-channel", dependencies: ["Channel", "LoggerAPI"])
    ],
    dependencies: [
        .Package(url: "https://github.com/baberthal/SwiftyJSON.git", majorVersion: 3),
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: 0, minor: 11),
        .Package(url: "https://github.com/baberthal/RingBuffer.git", majorVersion: 2),
        .Package(url: "../Quick", majorVersion: 0, minor: 10),
        .Package(url: "https://github.com/Quick/Nimble.git", majorVersion: 5)
    ],
    exclude: ["Makefile", "docs/*", "README.md"]
)
