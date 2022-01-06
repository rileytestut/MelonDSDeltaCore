//
//  MelonDSEmulatorBridge.hpp
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 1/4/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

#ifndef MelonDSEmulatorBridge_hpp
#define MelonDSEmulatorBridge_hpp

#include <stdio.h>
#include <stdbool.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE /* Nothing */
#endif

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef void (*BufferCallback)(const unsigned char *_Nonnull buffer, int size);
    typedef void (*VoidCallback)(void);

    double MelonDSFrameDuration();
    
void EMSCRIPTEN_KEEPALIVE MelonDSInitialize(const char *_Nonnull directoryPath, const char *_Nonnull resourcesPath, const char *_Nonnull bios7Path, const char *_Nonnull bios9Path, const char *_Nonnull firmwarePath);
    
    bool MelonDSStartEmulation(const char *_Nonnull gamePath);
    void MelonDSStopEmulation();
    void MelonDSPauseEmulation();
    void MelonDSResumeEmulation();
    
    void MelonDSRunFrame(bool processVideo);
    
    void MelonDSActivateInput(int input, double value);
    void MelonDSDeactivateInput(int input);
    void MelonDSResetInputs();
    
    void MelonDSSaveSaveState(const char *_Nonnull saveStatePath);
    void MelonDSLoadSaveState(const char *_Nonnull saveStatePath);
    
    void MelonDSSaveGameSave(const char *_Nonnull gameSavePath);
    void MelonDSLoadGameSave(const char *_Nonnull gameSavePath);
    
    bool MelonDSAddCheatCode(const char *_Nonnull cheatCode, const char *_Nonnull type);
    void MelonDSResetCheats();
    void MelonDSUpdateCheats();

    void MelonDSSetAudioCallback(_Nullable BufferCallback callback);
    void MelonDSSetVideoCallback(_Nullable BufferCallback callback);
    void MelonDSSetSaveCallback(_Nullable VoidCallback callback);
    
#if defined(__cplusplus)
}
#endif

#endif /* MelonDSEmulatorBridge_hpp */
