//
//  MelonDSEmulatorBridge+DeltaCore.h
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 11/15/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import "MelonDSEmulatorBridge.h"

NS_ASSUME_NONNULL_BEGIN

@interface MelonDSEmulatorBridge (DeltaCore)

- (void)registerForNotifications;

- (BOOL)inputsContainsTouchscreen:(uint32_t)inputs;
- (BOOL)inputsContainsLid:(uint32_t)inputs;

@end

NS_ASSUME_NONNULL_END
