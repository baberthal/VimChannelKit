import PackageDescription

let package = Package(
    name: "VimChannelKit",
    targets: [
        Target(name: "LoggerAPI", dependencies: []),
        Target(name: "Channel", dependencies: ["LoggerAPI"]),
        Target(name: "example-channel", dependencies: ["Channel", "LoggerAPI"])
    ],
    dependencies: [
        .Package(url: "https://github.com/baberthal/Yajl.git", "0.2.1"),
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", "0.11.22")
    ],
    exclude: ["Makefile", "docs/*", "README.md"]
)
