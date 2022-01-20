SRC_DIR := ../../..
BUILD_DIR := build

CC = /Users/rileytestut/Developer/Tools/emsdk/upstream/emscripten/emcc
CXX = /Users/rileytestut/Developer/Tools/emsdk/upstream/emscripten/em++

CFLAGS = -O3 -std=c11 -fno-signed-zeros -freciprocal-math -ffp-contract=fast -menable-unsafe-fp-math -enable-no-nans-fp-math -enable-no-infs-fp-math -fno-trapping-math -ffast-math -ffinite-math-only -flto -fno-rtti -fno-exceptions #-pthread
CXXFLAGS = -O3 -std=c++20 -fno-signed-zeros -freciprocal-math -ffp-contract=fast -menable-unsafe-fp-math -enable-no-nans-fp-math -enable-no-infs-fp-math -fno-trapping-math -ffast-math -ffinite-math-only -flto -fno-rtti -fno-exceptions -lwebsocket.js #-pthread

INCLUDE := -I../.. -I../../..

SOURCES = \
	$(wildcard $(SRC_DIR)/MelonDSDeltaCore/Bridge2/*.cpp) \
	$(wildcard $(SRC_DIR)/melonDS/src/*.c) $(wildcard ../../../melonDS/src/*.cpp) \
	$(wildcard $(SRC_DIR)/melonDS/src/**/*.c) $(wildcard ../../../melonDS/src/**/*.cpp) \
	
SOURCES := $(filter-out \
%/GPU3D_OpenGL.cpp %/OpenGLSupport.cpp %/GPU_OpenGL.cpp \
%/ARMJIT.cpp %/ARMJIT_Memory.cpp \
%/ARMJIT_A64/ARMJIT_ALU.cpp %/ARMJIT_A64/ARMJIT_Branch.cpp %/ARMJIT_A64/ARMJIT_Compiler.cpp %/ARMJIT_A64/ARMJIT_LoadStore.cpp \
%/ARMJIT_x64/ARMJIT_ALU.cpp %/ARMJIT_x64/ARMJIT_Branch.cpp %/ARMJIT_x64/ARMJIT_Compiler.cpp %/ARMJIT_x64/ARMJIT_GenOffsets.cpp %/ARMJIT_x64/ARMJIT_LoadStore.cpp \
%/dolphin/CommonFuncs.cpp %/dolphin/MathUtil.cpp %/dolphin/x64ABI.cpp %/dolphin/x64CPUDetect.cpp %/dolphin/x64Emitter.cpp \
%/frontend/Util_Audio.cpp %/frontend/Util_ROM.cpp %/frontend/Util_Video.cpp \
%/frontend/qt_sdl/AudioSettingsDialog.cpp %/frontend/qt_sdl/CheatsDialog.cpp %/frontend/qt_sdl/EmuSettingsDialog.cpp %/frontend/qt_sdl/Input.cpp %/frontend/qt_sdl/InputConfigDialog.cpp %/frontend/qt_sdl/LAN_PCap.cpp %/frontend/qt_sdl/LAN_Socket.cpp %/frontend/qt_sdl/main.cpp %/frontend/qt_sdl/OSD.cpp %/frontend/qt_sdl/Platform.cpp %/frontend/qt_sdl/VideoSettingsDialog.cpp %/frontend/qt_sdl/WifiSettingsDialog.cpp \
%/sha1/** \
, $(SOURCES) )

OBJ := $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SOURCES) )
OBJ := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(OBJ) )

EXPORTED_FUNCS = \
	"_main", \
    "_MelonDSFrameDuration", \
	"_MelonDSInitialize", \
	"_MelonDSStartEmulation", \
	"_MelonDSStopEmulation", \
	"_MelonDSRunFrame", \
	"_MelonDSActivateInput", \
	"_MelonDSDeactivateInput", \
	"_MelonDSResetInputs", \
	"_MelonDSSaveSaveState", \
	"_MelonDSLoadSaveState", \
	"_MelonDSSaveGameSave", \
	"_MelonDSLoadGameSave", \
	"_MelonDSAddCheatCode", \
	"_MelonDSResetCheats", \
	"_MelonDSSetAudioCallback", \
	"_MelonDSSetVideoCallback", \
	"_MelonDSSetSaveCallback"

EXPORTED_RUNTIME_FUNCS = \
	"ccall", \
	"allocate", \
	"intArrayFromString", \
	"FS", \
	"writeFile", \
	"readFile", \
	"HEAPU8", \
	"addFunction", \
	"ALLOC_NORMAL", \
	"getValue", \
	"stat", \
	"printErr"
        

EMFLAGS = --memory-init-file 1 --post-js post.js --preload-file biosnds7.rom --preload-file biosnds9.rom --preload-file firmware.bin -s WASM=1 -s EXPORTED_FUNCTIONS='[$(EXPORTED_FUNCS)]' -s EXPORTED_RUNTIME_METHODS='[$(EXPORTED_RUNTIME_FUNCS)]' -s ALLOW_MEMORY_GROWTH=1 -s ALLOW_TABLE_GROWTH=1 -s ENVIRONMENT=web -s FULL_ES3=1

#-s NO_DISABLE_EXCEPTION_CATCHING -s TOTAL_STACK=10MB -s INITIAL_MEMORY=50MB -s STACK_OVERFLOW_CHECK=1 -s RESERVED_FUNCTION_POINTERS=5 -s USE_PTHREADS=1 -s PTHREAD_POOL_SIZE=2

build: $(OBJ)
	$(CXX) $(CXXFLAGS) $(EMFLAGS) $(INCLUDE) $(OBJ) -o melonds.html
	
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(EMFLAGS) $(INCLUDE) -c $< -o $@
	
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(EMFLAGS) $(INCLUDE) -c $< -o $@

clean:
	echo "[RSTLog] Cleaning Build"
	-@rm -rvf build
	-@rm -rvf melonds.html
