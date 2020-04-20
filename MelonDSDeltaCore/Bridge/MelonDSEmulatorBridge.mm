//
//  MelonDSEmulatorBridge.m
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 10/31/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "MelonDSEmulatorBridge.h"

#import <UIKit/UIKit.h> // Prevent undeclared symbols in below headers

#import <DeltaCore/DeltaCore-Swift.h>
#import <MelonDSDeltaCore/MelonDSDeltaCore-Swift.h>

#include "Platform.h"
#include "NDS.h"
#include "SPU.h"
#include "GPU.h"

@interface MelonDSEmulatorBridge ()

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;

@property (nonatomic, getter=isInitialized) BOOL initialized;

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
    if ([self isInitialized])
    {
        NDS::DeInit();
    }
    
    NDS::Init();
    self.initialized = YES;
    
    GPU3D::InitRenderer(false);
        
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:gameURL.path isDirectory:&isDirectory] && !isDirectory)
    {
        if (!NDS::LoadROM(gameURL.fileSystemRepresentation, "", YES))
        {
            NSLog(@"Failed to load Nintendo DS ROM.");
        }
    }
    else
    {
        NDS::LoadBIOS();
    }
}

- (void)stop
{
    NDS::Stop();
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
    NDS::RunFrame();
    
    static int16_t buffer[0x1000];
    u32 availableBytes = SPU::GetOutputSize();
    availableBytes = MAX(availableBytes, (u32)(sizeof(buffer) / (2 * sizeof(int16_t))));
       
    int samples = SPU::ReadOutput(buffer, availableBytes);
    [self.audioRenderer.audioBuffer writeBuffer:buffer size:samples * 4];
    
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
}

- (void)deactivateInput:(NSInteger)input
{
}

- (void)resetInputs
{
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
    return YES;
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

- (NSURL *)bios7URL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"bios7.bin"];
}

- (NSURL *)bios9URL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"bios9.bin"];
}

- (NSURL *)firmwareURL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"firmware.bin"];
}

@end

namespace Platform
{
    void StopEmu()
    {
    }
    
    FILE* OpenFile(const char* path, const char* mode, bool mustexist)
    {
        FILE* ret;
        
        if (mustexist)
        {
            ret = fopen(path, "rb");
            if (ret) ret = freopen(path, mode, ret);
        }
        else
            ret = fopen(path, mode);
        
        return ret;
    }
    
    FILE* OpenLocalFile(const char* path, const char* mode)
    {
        NSURL *fileURL = [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@(path)];
        return OpenFile(fileURL.fileSystemRepresentation, mode);
    }
    
    FILE* OpenDataFile(const char* path)
    {
        NSString *resourceName = [@(path) stringByDeletingPathExtension];
        NSString *extension = [@(path) pathExtension];
        
        NSURL *fileURL = [MelonDSEmulatorBridge.dsResources URLForResource:resourceName withExtension:extension];
        return OpenFile(fileURL.fileSystemRepresentation, "rb");
    }
    
    void *Thread_Create(void (*func)())
    {
        return NULL;
    }
    
    void Thread_Free(void* thread)
    {
    }
    
    void Thread_Wait(void* thread)
    {
    }
    
    void *Semaphore_Create()
    {
        return NULL;
    }
    
    void Semaphore_Free(void *semaphore)
    {
    }
    
    void Semaphore_Reset(void *semaphore)
    {
    }
    
    void Semaphore_Wait(void *semaphore)
    {
    }

    void Semaphore_Post(void *semaphore)
    {
    }
    
    void *GL_GetProcAddress(const char* proc)
    {
        return NULL;
    }
    
    bool MP_Init()
    {
        return false;
    }
    
    void MP_DeInit()
    {
    }
    
    int MP_SendPacket(u8* bytes, int len)
    {
        return 0;
    }
    
    int MP_RecvPacket(u8* bytes, bool block)
    {
        return 0;
    }
    
    bool LAN_Init()
    {
        return false;
    }
    
    void LAN_DeInit()
    {
    }
    
    int LAN_SendPacket(u8* data, int len)
    {
        return 0;
    }
    
    int LAN_RecvPacket(u8* data)
    {
        return 0;
    }
}

namespace GPU3D
{
namespace GLRenderer
{
    bool Init()
    {
        return false;
    }
    
    void DeInit()
    {
    }
    
    void Reset()
    {
    }

    void UpdateDisplaySettings()
    {
    }

    void RenderFrame()
    {
    }
    
    void PrepareCaptureFrame()
    {
    }
    
    u32* GetLine(int line)
    {
        return NULL;
    }
    
    void SetupAccelFrame()
    {
        return;
    }
}
}
