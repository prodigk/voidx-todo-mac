// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoidXTodoMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoidXTodoMac", targets: ["VoidXTodoMac"])
    ],
    targets: [
        .executableTarget(
            name: "VoidXTodoMac",
            path: "Sources/VoidXTodoMac"
        )
    ]
)
