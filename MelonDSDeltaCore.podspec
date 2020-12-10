Pod::Spec.new do |spec|
  spec.name         = "MelonDSDeltaCore"
  spec.version      = "0.1"
  spec.summary      = "Nintendo DS plug-in for Delta emulator."
  spec.description  = "iOS framework that wraps melonDS to allow playing Nintendo DS games with Delta emulator."
  spec.homepage     = "https://github.com/rileytestut/MelonDSDeltaCore"
  spec.platform     = :ios, "12.0"
  spec.source       = { :git => "https://github.com/rileytestut/MelonDSDeltaCore.git" }

  spec.author             = { "Riley Testut" => "riley@rileytestut.com" }
  spec.social_media_url   = "https://twitter.com/rileytestut"
  
  spec.source_files  = "MelonDSDeltaCore/**/*.{swift}", "MelonDSDeltaCore/MelonDSDeltaCore.h", "MelonDSDeltaCore/Bridge/MelonDSEmulatorBridge.{h,mm}", "MelonDSDeltaCore/Types/MelonDSTypes.{h,m}", "melonDS/src/*.{h,hpp,cpp}", "melonDS/src/frontend/qt_sdl/PlatformConfig.{h,cpp}", "melonDS/src/tiny-AES-c/*.{h,hpp,c}", "melonDS/src/ARMJIT_A64/*.{h,cpp,s}", "melonDS/src/dolphin/Arm64Emitter.{h,cpp}", "melonDS/src/xxhash/*.{h,c}"
  spec.exclude_files = "melonDS/src/GPU3D_OpenGL.cpp", "melonDS/src/OpenGLSupport.cpp", "melonDS/src/GPU_OpenGL.cpp"
  spec.public_header_files = "MelonDSDeltaCore/Types/MelonDSTypes.h", "MelonDSDeltaCore/Bridge/MelonDSEmulatorBridge.h", "MelonDSDeltaCore/MelonDSDeltaCore.h"
  spec.header_mappings_dir = ""
  spec.resource_bundles = {
    "melonDS" => ["MelonDSDeltaCore/**/*.deltamapping", "MelonDSDeltaCore/**/*.deltaskin"]
  }
  
  spec.dependency 'DeltaCore'
    
  spec.xcconfig = {
    "HEADER_SEARCH_PATHS" => '"${PODS_CONFIGURATION_BUILD_DIR}" "$(PODS_ROOT)/Headers/Private/MelonDSDeltaCore/melonDS/src"',
    "USER_HEADER_SEARCH_PATHS" => '"${PODS_CONFIGURATION_BUILD_DIR}/DeltaCore/Swift Compatibility Header"',
    "GCC_PREPROCESSOR_DEFINITIONS" => "STATIC_LIBRARY=1 JIT_ENABLED=1",
    "GCC_OPTIMIZATION_LEVEL" => "fast"
  }
  
end
