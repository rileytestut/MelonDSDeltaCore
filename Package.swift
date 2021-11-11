// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MelonDSDeltaCore",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "MelonDSDeltaCore",
            targets: ["MelonDSDeltaCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/rileytestut/DeltaCore.git", .branch("swiftpm"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MelonDSDeltaCore",
            dependencies: ["DeltaCore", "MelonDS", "MelonDSSwift", "MelonDSBridge"],
            path: "",
            exclude: [
                "MelonDSDeltaCore/Controller Skin/info.json",
                "MelonDSDeltaCore/Controller Skin/iphone_portrait.pdf",
                "MelonDSDeltaCore/Controller Skin/iphone_landscape.pdf",
                "MelonDSDeltaCore/Controller Skin/iphone_edgetoedge_portrait.pdf",
                "MelonDSDeltaCore/Controller Skin/iphone_edgetoedge_landscape.pdf"
            ],
            sources: [
                "MelonDSDeltaCore/MelonDS.swift"
            ],
            resources: [
                .copy("MelonDSDeltaCore/Controller Skin/Standard.deltaskin"),
                .copy("MelonDSDeltaCore/Standard.deltamapping"),
            ]
        ),
        .target(
            name: "MelonDSSwift",
            dependencies: ["DeltaCore"],
            path: "MelonDSDeltaCore",
            sources: ["MelonDSGameInput.swift"]
        ),
        .target(
            name: "MelonDSBridge",
            dependencies: ["DeltaCore", "MelonDS", "MelonDSSwift"],
            path: "MelonDSDeltaCore/Bridge",
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("../.."),
                .define("JIT_ENABLED", to: "1"),
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/m68k"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/z80"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/sound"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/cart_hw"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/cart_hw/svp"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/cd_hw"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/input_hw"),
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/core/ntsc"),
//
//                .headerSearchPath("../GenesisPlusGX/Genesis-Plus-GX/psp2"),
//
//                .define("USE_32BPP_RENDERING"),
//                .define("FLAC__HAS_OGG", to: "0"),
//                .define("HAVE_SYS_PARAM_H"),
//                .define("HAVE_LROUND"),
//                .define("PACKAGE_VERSION", to: "\"1.3.2\""),
//                .define("_7ZIP_ST"),
//                .define("LSB_FIRST")
            ]
        ),
        .target(
            name: "MelonDS",
            path: "melonDS",
            exclude: [
                "src/GPU3D_OpenGL.cpp",
                "src/OpenGLSupport.cpp",
                "src/GPU_OpenGL.cpp",
                
                "src/ARMJIT_x64",
                
                "src/dolphin/CommonFuncs.cpp",
                "src/dolphin/MathUtil.cpp",
                "src/dolphin/x64ABI.cpp",
                "src/dolphin/x64CPUDetect.cpp",
                "src/dolphin/x64Emitter.cpp",
                
                "src/frontend/Util_Audio.cpp",
                "src/frontend/Util_ROM.cpp",
                "src/frontend/Util_Video.cpp",
                
                "src/frontend/qt_sdl/pcap",
                "src/frontend/qt_sdl/AudioSettingsDialog.cpp",
                "src/frontend/qt_sdl/CheatsDialog.cpp",
                "src/frontend/qt_sdl/EmuSettingsDialog.cpp",
                "src/frontend/qt_sdl/Input.cpp",
                "src/frontend/qt_sdl/InputConfigDialog.cpp",
                "src/frontend/qt_sdl/LAN_PCap.cpp",
                "src/frontend/qt_sdl/LAN_Socket.cpp",
                "src/frontend/qt_sdl/main.cpp",
                "src/frontend/qt_sdl/OSD.cpp",
                "src/frontend/qt_sdl/Platform.cpp",
                "src/frontend/qt_sdl/VideoSettingsDialog.cpp",
                "src/frontend/qt_sdl/WifiSettingsDialog.cpp",
                
                "src/sha1",
            ],
            sources: [
                "src"
            ],
            cSettings: [
                .headerSearchPath("src"),
                .define("JIT_ENABLED", to: "1"),
                
                .unsafeFlags(["-fvisibility-inlines-hidden"])
//                .headerSearchPath("Genesis-Plus-GX/core/m68k"),
//                .headerSearchPath("Genesis-Plus-GX/core/z80"),
//                .headerSearchPath("Genesis-Plus-GX/core/sound"),
//                .headerSearchPath("Genesis-Plus-GX/core/cart_hw"),
//                .headerSearchPath("Genesis-Plus-GX/core/cart_hw/svp"),
//                .headerSearchPath("Genesis-Plus-GX/core/cd_hw"),
//                .headerSearchPath("Genesis-Plus-GX/core/cd_hw/libchdr/deps/lzma"),
//                .headerSearchPath("Genesis-Plus-GX/core/cd_hw/libchdr/deps/libFLAC/include"),
//                .headerSearchPath("Genesis-Plus-GX/core/input_hw"),
//                .headerSearchPath("Genesis-Plus-GX/core/ntsc"),
//
//                .headerSearchPath("Genesis-Plus-GX/psp2"),
                
//                .define("JIT_ENABLED")
            ]
        )
    ],
    cxxLanguageStandard: .cxx14
)
