//
//  MelonDSEmulatorBridge.h
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 10/31/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DLTAEmulatorBridging;

NS_ASSUME_NONNULL_BEGIN

@interface MelonDSEmulatorBridge : NSObject <DLTAEmulatorBridging>

@property (class, nonatomic, readonly) MelonDSEmulatorBridge *sharedBridge;

@end

NS_ASSUME_NONNULL_END
