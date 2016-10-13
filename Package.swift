import PackageDescription

let package = Package(
    name: "SocketServer",
    targets: [
        Target(name: "LoggerAPI", dependencies: []),
        Target(name: "SocketServer", dependencies: ["LoggerAPI"]),
        Target(name: "example-channel", dependencies: ["SocketServer", "LoggerAPI"])
    ],
    dependencies: [
        .Package(url: "https://github.com/baberthal/Yajl.git", "0.2.1"),
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", "0.11.22")
    ],
    exclude: ["Makefile", "docs/*", "README.md"]
)
