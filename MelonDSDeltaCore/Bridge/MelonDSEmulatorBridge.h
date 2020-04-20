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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Silence "Cannot find protocol definition" warning due to forward declaration.
@interface MelonDSEmulatorBridge : NSObject <DLTAEmulatorBridging>
#pragma clang diagnostic pop

@property (class, nonatomic, readonly) MelonDSEmulatorBridge *sharedBridge;

@property (nonatomic, readonly) NSURL *bios7URL;
@property (nonatomic, readonly) NSURL *bios9URL;
@property (nonatomic, readonly) NSURL *firmwareURL;

@end

NS_ASSUME_NONNULL_END
