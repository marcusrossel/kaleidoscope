// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kaleidoscope",
    
    platforms: [
        .macOS(.v10_14), // Necessary to use LLVM.
    ],
    
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "Kaleidoscope",
            targets: ["Kaleidoscope"]
        ),
    ],
    
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/marcusrossel/lexer-protocol", .branch("master")),
    ],
    
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .systemLibrary(
            name: "CLLVM",
            pkgConfig: "cllvm",
            providers: [.brew(["llvm"])]
        ),
        .target(
            name: "Kaleidoscope",
            dependencies: ["LexerProtocol", "CLLVM"]
        ),
        .testTarget(
            name: "KaleidoscopeTests",
            dependencies: ["Kaleidoscope"]
        ),
    ],
    
    cxxLanguageStandard: .cxx14 // Maybe this is needed? (https://forums.swift.org/t/llvm-is-now-on-c-14/27931)
)
