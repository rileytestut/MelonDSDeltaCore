//
//  MelonDSEmulatorBridge+Private.h
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 11/15/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import "MelonDSEmulatorBridge.h"

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface MelonDSEmulatorBridge ()
{
    int _notifyToken;
}

@property (nonatomic) uint32_t activatedInputs;
@property (nonatomic) CGPoint touchScreenPoint;

@end

NS_ASSUME_NONNULL_END
