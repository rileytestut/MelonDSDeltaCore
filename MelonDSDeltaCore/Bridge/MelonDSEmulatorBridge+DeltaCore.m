//
//  MelonDSEmulatorBridge+DeltaCore.m
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 11/15/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import "MelonDSEmulatorBridge+DeltaCore.h"
#import "MelonDSEmulatorBridge+Private.h"

#import <notify.h>

#if SWIFT_PACKAGE
@import MelonDSSwift;
#else
#import "MelonDSDeltaCore-Swift.h"
#endif

@implementation MelonDSEmulatorBridge (DeltaCore)

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)input value:(double)value
{
    self.activatedInputs |= (uint32_t)input;
    
    CGPoint touchPoint = self.touchScreenPoint;
    
    switch ((MelonDSGameInput)input)
    {
    case MelonDSGameInputTouchScreenX:
        touchPoint.x = value * (256 - 1);
        break;
        
    case MelonDSGameInputTouchScreenY:
        touchPoint.y = value * (192 - 1);
        break;
            
    default: break;
    }

    self.touchScreenPoint = touchPoint;
}

- (void)deactivateInput:(NSInteger)input
{
    self.activatedInputs &= ~((uint32_t)input);
    
    CGPoint touchPoint = self.touchScreenPoint;
    
    switch ((MelonDSGameInput)input)
    {
        case MelonDSGameInputTouchScreenX:
            touchPoint.x = 0;
            break;
            
        case MelonDSGameInputTouchScreenY:
            touchPoint.y = 0;
            break;
            
        default: break;
    }
    
    self.touchScreenPoint = touchPoint;
}

- (void)resetInputs
{
    self.activatedInputs = 0;
    self.touchScreenPoint = CGPointZero;
}

#pragma mark - Notifications -

- (void)registerForNotifications
{
    int status = notify_register_dispatch("com.apple.springboard.hasBlankedScreen", &_notifyToken, dispatch_get_main_queue(), ^(int t) {
        uint64_t state;
        int result = notify_get_state(_notifyToken, &state);
        NSLog(@"Lock screen state = %llu", state);
        
        if (state == 0)
        {
            [self deactivateInput:MelonDSGameInputLid];
        }
        else
        {
            [self activateInput:MelonDSGameInputLid value:1];
        }
        
        if (result != NOTIFY_STATUS_OK)
        {
            NSLog(@"Lock screen notification returned: %d", result);
        }
    });
    
    if (status != NOTIFY_STATUS_OK)
    {
        NSLog(@"Lock screen notification registration returned: %d", status);
    }
}

#pragma mark - Helpers -

- (BOOL)inputsContainsTouchscreen:(uint32_t)inputs
{
    BOOL containsTouchscreen = (inputs & MelonDSGameInputTouchScreenX || inputs & MelonDSGameInputTouchScreenY);
    return containsTouchscreen;
}

- (BOOL)inputsContainsLid:(uint32_t)inputs
{
    BOOL containsLid = (inputs & MelonDSGameInputLid);
    return containsLid;
}

@end
