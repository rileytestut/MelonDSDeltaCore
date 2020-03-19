//
//  MelonDS.swift
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 10/31/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation
import AVFoundation

import DeltaCore

public extension GameType
{
    static let melonDS = GameType("com.rileytestut.delta.game.ds")
}

@objc public enum MelonDSGameInput: Int, Input
{
    case a = 1
    case b = 2
    case select = 4
    case start = 8
    case right = 16
    case left = 32
    case up = 64
    case down = 128
    case r = 256
    case l = 512
    case x = 1024
    case y = 2048
    
    case touchScreenX = 4096
    case touchScreenY = 8192
    
    public var type: InputType {
        return .game(.melonDS)
    }
    
    public var isContinuous: Bool {
        switch self
        {
        case .touchScreenX, .touchScreenY: return true
        default: return false
        }
    }
}

public struct MelonDS: DeltaCoreProtocol
{
    public var name: String { "MelonDSDeltaCore" }
    public var identifier: String { "com.rileytestut.MelonDSDeltaCore" }
    
    public static let core = MelonDS()
    
    public let gameType = GameType.melonDS
    
    public let gameInputType: Input.Type = MelonDSGameInput.self
    
    public let gameSaveFileExtension = "dsv"
    
    public var audioFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    }
    
    public var videoFormat: VideoFormat {
        return VideoFormat(format: .bitmap(.bgra8), dimensions: CGSize(width: 256, height: 384))
    }
    
    public var supportedCheatFormats: Set<CheatFormat> {
        return []
    }
    
    public var emulatorBridge: EmulatorBridging {
        let bridge = (NSClassFromString("MelonDSEmulatorBridge") as! NSObject.Type).perform("sharedBridge")!.takeUnretainedValue() as! EmulatorBridging
        return bridge
    }
    
    public var resourceBundle: Bundle {
        let bundle = Bundle(identifier: "com.rileytestut.MelonDSDeltaCore")!
        return bundle
    }
    
    private init()
    {
    }
}
