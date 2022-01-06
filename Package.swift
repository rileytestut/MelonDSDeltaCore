// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let targets: [String]
let dependencies: [Target.Dependency]
let defines: String

#if os(iOS)
targets = ["MelonDSDeltaCore"]
dependencies = ["DeltaCore"]
defines = "JAVASCRIPT"
#else
targets = ["MelonDSDeltaCore", "MelonDSBridge"]
dependencies = ["DeltaCore", "MelonDSBridge"]
defines = "NATIVE"
#endif

let package = Package(
    name: "MelonDSDeltaCore",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "MelonDSDeltaCore",
            targets: targets
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "DeltaCore", url: "https://github.com/rileytestut/DeltaCore.git", .upToNextMajor(from: "0.1.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MelonDSDeltaCore",
            dependencies: dependencies,
            path: "",
            exclude: [
                "melonDS",
                "MelonDSDeltaCore.podspec",
                "MelonDSDeltaCore.xcodeproj",
                
                "MelonDSDeltaCore/Bridge",
                "MelonDSDeltaCore/Bridge2",
                "MelonDSDeltaCore/Types",
                "MelonDSDeltaCore/Info.plist",
                
                "MelonDSDeltaCore/Controller Skin/info.json",
                "MelonDSDeltaCore/Controller Skin/iphone_portrait.pdf",
                "MelonDSDeltaCore/Controller Skin/iphone_landscape.pdf",
                "MelonDSDeltaCore/Controller Skin/iphone_edgetoedge_portrait.pdf",
                "MelonDSDeltaCore/Controller Skin/iphone_edgetoedge_landscape.pdf"
            ],
            sources: [
                "MelonDSDeltaCore/MelonDS.swift",
                "MelonDSDeltaCore/MelonDSGameInput.swift",
                "MelonDSDeltaCore/MelonDSEmulatorBridge.swift"
            ],
            resources: [
                .copy("MelonDSDeltaCore/Controller Skin/Standard.deltaskin"),
                .copy("MelonDSDeltaCore/Standard.deltamapping"),
                .copy("MelonDSDeltaCore/biosnds7.rom"),
                .copy("MelonDSDeltaCore/biosnds9.rom"),
                .copy("MelonDSDeltaCore/firmware.bin"),
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE"),
                .define(defines)
            ]
        ),
//        .target(
//            name: "MelonDSSwift",
//            dependencies: ["DeltaCore"],
//            path: "MelonDSDeltaCore",
//            exclude: [
//                "Bridge",
//                "Controller Skin",
//                "Types",
//
//                "MelonDS.swift",
//
//                "Info.plist",
//                "Standard.deltamapping",
//            ],
//            sources: [
//                "MelonDSGameInput.swift"
//            ]
//        ),
        .target(
            name: "MelonDSBridge",
            dependencies: ["MelonDS"/*, "MelonDSSwift"*/],
            path: "MelonDSDeltaCore/Bridge2",
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("../.."),
                .define("JIT_ENABLED", to: "1"),
            ]
        ),
        .target(
            name: "MelonDS",
            path: "melonDS/src",
            exclude: [
                "GPU3D_OpenGL.cpp",
                "OpenGLSupport.cpp",
                "GPU_OpenGL.cpp",
                
                "CMakeLists.txt",
                
                "ARMJIT_x64",
                
                "dolphin/CommonFuncs.cpp",
                "dolphin/MathUtil.cpp",
                "dolphin/x64ABI.cpp",
                "dolphin/x64CPUDetect.cpp",
                "dolphin/x64Emitter.cpp",
                "dolphin/license_dolphin.txt",
                
                "frontend/Util_Audio.cpp",
                "frontend/Util_ROM.cpp",
                "frontend/Util_Video.cpp",
                
                "frontend/qt_sdl/AudioSettingsDialog.ui",
                "frontend/qt_sdl/CheatsDialog.ui",
                "frontend/qt_sdl/CMakeLists.txt",
                "frontend/qt_sdl/EmuSettingsDialog.ui",
                "frontend/qt_sdl/InputConfigDialog.ui",
                "frontend/qt_sdl/VideoSettingsDialog.ui",
                "frontend/qt_sdl/WifiSettingsDialog.ui",
                
                "frontend/qt_sdl/pcap",
                
                "frontend/qt_sdl/AudioSettingsDialog.cpp",
                "frontend/qt_sdl/CheatsDialog.cpp",
                "frontend/qt_sdl/EmuSettingsDialog.cpp",
                "frontend/qt_sdl/Input.cpp",
                "frontend/qt_sdl/InputConfigDialog.cpp",
                "frontend/qt_sdl/LAN_PCap.cpp",
                "frontend/qt_sdl/LAN_Socket.cpp",
                "frontend/qt_sdl/main.cpp",
                "frontend/qt_sdl/OSD.cpp",
                "frontend/qt_sdl/Platform.cpp",
                "frontend/qt_sdl/VideoSettingsDialog.cpp",
                "frontend/qt_sdl/WifiSettingsDialog.cpp",
                
                "sha1",
                
                "tiny-AES-c/README.md",
                "tiny-AES-c/unlicense.txt"
            ],
            sources: [
                ""
            ],
            cSettings: [
                .headerSearchPath(""),
                .define("JIT_ENABLED", to: "1"),
                .unsafeFlags(["-O3"])
            ]
        )
    ],
    cxxLanguageStandard: .cxx14
)
