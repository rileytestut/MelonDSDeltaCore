//
//  MelonDSEmulatorBridge.swift
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 1/4/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

import Foundation
import DeltaCore

#if NATIVE
import MelonDSBridge
#endif

class MelonDSEmulatorBridge: AdaptableDeltaBridge
{
    public static let shared = MelonDSEmulatorBridge()
    
    var coreDirectoryURL: URL?
    var coreResourcesURL: URL?
    
    private var isPrepared = false
        
    override var adapter: EmulatorBridging {
#if !NATIVE
        let scriptURL = Bundle.module.url(forResource: "melonds", withExtension: "html")!
        
        let adapter = JSCoreAdapter(prefix: "MelonDS", fileURL: scriptURL)
        adapter.emulatorCore = self.emulatorCore
        return adapter
#else
        return NativeCoreAdapter(
            frameDuration: MelonDSFrameDuration,
            start: MelonDSStartEmulation,
            stop: MelonDSStopEmulation,
            pause: MelonDSPauseEmulation,
            resume: MelonDSResumeEmulation,
            runFrame: MelonDSRunFrame,
            activateInput: MelonDSActivateInput,
            deactivateInput: MelonDSDeactivateInput,
            resetInputs: MelonDSResetInputs,
            saveSaveState: MelonDSSaveSaveState,
            loadSaveState: MelonDSLoadSaveState,
            saveGameSave: MelonDSSaveGameSave,
            loadGameSave: MelonDSLoadGameSave,
            addCheatCode: MelonDSAddCheatCode,
            resetCheats: MelonDSResetCheats,
            updateCheats: MelonDSUpdateCheats,
            setAudioCallback: MelonDSSetAudioCallback,
            setVideoCallback: MelonDSSetVideoCallback,
            setSaveCallback: MelonDSSetSaveCallback)
#endif
    }
    
    override func start(withGameURL gameURL: URL)
    {
#if NATIVE
        if !self.isPrepared
        {
            let coreDirectoryURL = self.coreDirectoryURL!
            let coreResourcesURL = self.coreResourcesURL!
            
            let bios7Path = Bundle.module.path(forResource: "biosnds7", ofType: "rom")!
            let bios9Path = Bundle.module.path(forResource: "biosnds9", ofType: "rom")!
            let firmwarePath = Bundle.module.path(forResource: "firmware", ofType: "bin")!
            
            MelonDSInitialize(coreDirectoryURL.path, coreResourcesURL.path, bios7Path, bios9Path, firmwarePath)
            
            self.isPrepared = true
        }
#endif
        
        super.start(withGameURL: gameURL)
    }
}

