//
//  MelonDSGameInput.swift
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 11/5/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

import DeltaCore

// Declared in MelonDSSwift so we can use it from MelonDSBridge.
@objc public enum MelonDSGameInput: Int, _Input
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
    
    case lid = 16_384
}
