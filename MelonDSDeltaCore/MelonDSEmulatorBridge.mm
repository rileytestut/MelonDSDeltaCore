//
//  MelonDSEmulatorBridge.m
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 10/31/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "MelonDSEmulatorBridge.h"

#import <DSDeltaCore/DSDeltaCore-Swift.h>

#include "../melonDS/src/NDS.h"
#include "../melonDS/src/GPU.h"
#include "../melonDS/src/SPU.h"
#include "../melonDS/src/Wifi.h"
#include "../melonDS/src/Platform.h"
#include "../melonDS/src/Config.h"
#include "../melonDS/src/SPU.h"

#include "../melonDS/src/Savestate.h"

char* EmuDirectory;

void Stop(bool internal)
{
}

@interface MelonDSEmulatorBridge ()

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;

@property (nonatomic) uint32_t activatedInputs;
@property (nonatomic) CGPoint touchScreenPoint;

@end

@implementation MelonDSEmulatorBridge
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;
@synthesize saveUpdateHandler = _saveUpdateHandler;

+ (instancetype)sharedBridge
{
    static MelonDSEmulatorBridge *_emulatorBridge = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emulatorBridge = [[self alloc] init];
    });
    
    return _emulatorBridge;
}

#pragma mark - Emulation State -

- (void)startWithGameURL:(NSURL *)gameURL
{
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    
    NSBundle *bundle = [NSBundle bundleForClass:[MelonDSEmulatorBridge class]];
    NSArray<NSString *> *filenames = @[@"bios7.rom", @"bios9.rom", @"firmware.bin"];
    
    for (NSString *filename in filenames)
    {
        NSURL *sourceURL = [bundle.bundleURL URLByAppendingPathComponent:filename];
        NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:filename];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path])
        {
            [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destinationURL error:nil];
        }
    }
    
    NDS::Init();
        
//    NSURL *directoryURL = [gameURL URLByDeletingLastPathComponent];
    EmuDirectory = (char *)documentsDirectory.fileSystemRepresentation;
    
//    NSURL *gameDirectory = [NSURL URLWithString:@"/dev/null"];
    
    NSURL *saveFileURL = [[gameURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"melonSAV"];
    
    if (NDS::LoadROM(gameURL.fileSystemRepresentation, saveFileURL.fileSystemRepresentation, true))
    {
        NSLog(@"Loaded!");
    }
    else
    {
        NSLog(@"Failed :(");
    }
}

- (void)stop
{
}

- (void)pause
{
}

- (void)resume
{
}

#pragma mark - Game Loop -

- (void)runFrameAndProcessVideo:(BOOL)processVideo
{
    if (self.activatedInputs & DSGameInputTouchScreenX || self.activatedInputs & DSGameInputTouchScreenY)
    {
        NSLog(@"Touching: %@ %@", @(self.touchScreenPoint.x), @(self.touchScreenPoint.y));
        NDS::TouchScreen(self.touchScreenPoint.x, self.touchScreenPoint.y);
    }
    else
    {
        NDS::ReleaseScreen();
    }
    
    NDS::RunFrame();
    
    static int16_t buffer[0x1000];
    u32 avail = SPU::GetOutputSize();
    if(avail > sizeof(buffer) / (2 * sizeof(int16_t)))
       avail = sizeof(buffer) / (2 * sizeof(int16_t));

    int samples = SPU::ReadOutput(buffer, avail);
    
    int bytes = samples * 4;
    [self.audioRenderer.audioBuffer writeBuffer:buffer size:bytes];
    
    if (processVideo)
    {
        int screenBufferSize = 256 * 192 * 4;
        
        memcpy(self.videoRenderer.videoBuffer, GPU::Framebuffer[GPU::FrontBuffer][0], screenBufferSize);
        memcpy(self.videoRenderer.videoBuffer + screenBufferSize, GPU::Framebuffer[GPU::FrontBuffer][1], screenBufferSize);
        
        [self.videoRenderer processFrame];
    }
}

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)input value:(double)value
{
    self.activatedInputs |= (uint32_t)input;
    
    CGPoint touchPoint = self.touchScreenPoint;
    
    switch ((DSGameInput)input)
    {
    case DSGameInputTouchScreenX:
        touchPoint.x = value * 256;
        break;
        
    case DSGameInputTouchScreenY:
        touchPoint.y = value * 192;
        break;
            
    default: break;
    }

    self.touchScreenPoint = touchPoint;
}

- (void)deactivateInput:(NSInteger)input
{
    self.activatedInputs &= ~((uint32_t)input);
    
    CGPoint touchPoint = self.touchScreenPoint;
    
    switch ((DSGameInput)input)
    {
        case DSGameInputTouchScreenX:
            touchPoint.x = 0;
            break;
            
        case DSGameInputTouchScreenY:
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

#pragma mark - Game Saves -

- (void)saveGameSaveToURL:(NSURL *)URL
{
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
}

#pragma mark - Save States -

- (void)saveSaveStateToURL:(NSURL *)URL
{
}

- (void)loadSaveStateFromURL:(NSURL *)URL
{
}

#pragma mark - Cheats -

- (BOOL)addCheatCode:(NSString *)cheatCode type:(NSString *)type
{
    return NO;
}

- (void)resetCheats
{
}

- (void)updateCheats
{
}


#pragma mark - Getters/Setters -

- (NSTimeInterval)frameDuration
{
    return (1.0 / 60.0);
}

@end

