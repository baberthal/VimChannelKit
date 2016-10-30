import PackageDescription

let package = Package(
    name: "VimChannelKit",
    targets: [
        Target(name: "LoggerAPI", dependencies: []),
        Target(name: "SimpleNet", dependencies: []),
        Target(name: "Channel", dependencies: ["LoggerAPI", "SimpleNet"]),
        Target(name: "example-channel", dependencies: ["Channel", "LoggerAPI"])
    ],
    dependencies: [
        .Package(url: "https://github.com/baberthal/SwiftyJSON.git",
                 majorVersion: 3),
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git",
                 majorVersion: 0, minor: 11)
    ],
    exclude: ["Makefile", "docs/*", "README.md"]
)
