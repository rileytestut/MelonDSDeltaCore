//
//  MelonDSEmulatorBridge.m
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 10/31/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "MelonDSEmulatorBridge.h"

#import <UIKit/UIKit.h> // Prevent undeclared symbols in below headers

#import <DeltaCore/DeltaCore.h>
#import <DeltaCore/DeltaCore-Swift.h>

#if STATIC_LIBRARY
#import "MelonDSDeltaCore-Swift.h"
#else
#import <MelonDSDeltaCore/MelonDSDeltaCore-Swift.h>
#endif

#include "melonDS/src/Platform.h"
#include "melonDS/src/NDS.h"
#include "melonDS/src/SPU.h"
#include "melonDS/src/GPU.h"
#include "melonDS/src/AREngine.h"

#include "melonDS/src/Config.h"

#include <memory>

#import <notify.h>

// Copied from melonDS source (no longer exists in HEAD)
void ParseTextCode(char* text, int tlen, u32* code, int clen) // or whatever this should be named?
{
    u32 cur_word = 0;
    u32 ndigits = 0;
    u32 nin = 0;
    u32 nout = 0;

    char c;
    while ((c = *text++) != '\0')
    {
        u32 val;
        if (c >= '0' && c <= '9')
            val = c - '0';
        else if (c >= 'a' && c <= 'f')
            val = c - 'a' + 0xA;
        else if (c >= 'A' && c <= 'F')
            val = c - 'A' + 0xA;
        else
            continue;

        cur_word <<= 4;
        cur_word |= val;

        ndigits++;
        if (ndigits >= 8)
        {
            if (nout >= clen)
            {
                printf("AR: code too long!\n");
                return;
            }

            *code++ = cur_word;
            nout++;

            ndigits = 0;
            cur_word = 0;
        }

        nin++;
        if (nin >= tlen) break;
    }

    if (nout & 1)
    {
        printf("AR: code was missing one word\n");
        if (nout >= clen)
        {
            printf("AR: code too long!\n");
            return;
        }
        *code++ = 0;
    }
}

@interface MelonDSEmulatorBridge ()

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;

@property (nonatomic) uint32_t activatedInputs;
@property (nonatomic) CGPoint touchScreenPoint;

@property (nonatomic, readonly) std::shared_ptr<ARCodeFile> cheatCodes;
@property (nonatomic, readonly) int notifyToken;

@property (nonatomic, getter=isInitialized) BOOL initialized;
@property (nonatomic, getter=isStopping) BOOL stopping;

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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cheatCodes = std::make_shared<ARCodeFile>("");
        _activatedInputs = 0;
    }
    
    return self;
}

#pragma mark - Emulation State -

- (void)startWithGameURL:(NSURL *)gameURL
{
    self.gameURL = gameURL;
    
    if ([self isInitialized])
    {
        NDS::DeInit();
    }
    else
    {
        // DS paths
        strncpy(Config::BIOS7Path, self.bios7URL.lastPathComponent.UTF8String, self.bios7URL.lastPathComponent.length);
        strncpy(Config::BIOS9Path, self.bios9URL.lastPathComponent.UTF8String, self.bios9URL.lastPathComponent.length);
        strncpy(Config::FirmwarePath, self.firmwareURL.lastPathComponent.UTF8String, self.firmwareURL.lastPathComponent.length);
        
        // DSi paths
        strncpy(Config::DSiBIOS7Path, self.dsiBIOS7URL.lastPathComponent.UTF8String, self.dsiBIOS7URL.lastPathComponent.length);
        strncpy(Config::DSiBIOS9Path, self.dsiBIOS9URL.lastPathComponent.UTF8String, self.dsiBIOS9URL.lastPathComponent.length);
        strncpy(Config::DSiFirmwarePath, self.dsiFirmwareURL.lastPathComponent.UTF8String, self.dsiFirmwareURL.lastPathComponent.length);
        strncpy(Config::DSiNANDPath, self.dsiNANDURL.lastPathComponent.UTF8String, self.dsiNANDURL.lastPathComponent.length);
        
        [self registerForNotifications];
    }
    
    NDS::SetConsoleType((int)self.systemType);

    NDS::Init();
    self.initialized = YES;
        
    GPU::RenderSettings settings;
    settings.Soft_Threaded = NO;

    GPU::InitRenderer(0);
    GPU::SetRenderSettings(0, settings);
    
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
    
    self.stopping = NO;
}

- (void)stop
{
    self.stopping = YES;
    
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
    if ([self isStopping])
    {
        return;
    }
    
    uint32_t inputs = self.activatedInputs;
    uint32_t inputsMask = 0xFFF; // 0b000000111111111111;
    
    uint16_t sanitizedInputs = inputsMask ^ inputs;
    NDS::SetKeyMask(sanitizedInputs);
    
    if (self.activatedInputs & MelonDSGameInputTouchScreenX || self.activatedInputs & MelonDSGameInputTouchScreenY)
    {
        NDS::TouchScreen(self.touchScreenPoint.x, self.touchScreenPoint.y);
    }
    else
    {
        NDS::ReleaseScreen();
    }
    
    if (self.activatedInputs & MelonDSGameInputLid)
    {
        NDS::SetLidClosed(true);
    }
    else if (NDS::IsLidClosed())
    {
        NDS::SetLidClosed(false);
    }
    
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

#pragma mark - Game Saves -

- (void)saveGameSaveToURL:(NSURL *)URL
{
    NDS::RelocateSave(URL.fileSystemRepresentation, true);
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:URL.path])
    {
        return;
    }
    
    NDS::RelocateSave(URL.fileSystemRepresentation, false);
}

#pragma mark - Save States -

- (void)saveSaveStateToURL:(NSURL *)URL
{
    Savestate *savestate = new Savestate(URL.fileSystemRepresentation, true);
    NDS::DoSavestate(savestate);
    delete savestate;
}

- (void)loadSaveStateFromURL:(NSURL *)URL
{
    Savestate *savestate = new Savestate(URL.fileSystemRepresentation, false);
    NDS::DoSavestate(savestate);
    delete savestate;
}

#pragma mark - Cheats -

- (BOOL)addCheatCode:(NSString *)cheatCode type:(NSString *)type
{
    NSArray<NSString *> *codes = [cheatCode componentsSeparatedByString:@"\n"];
    for (NSString *code in codes)
    {
        if (code.length != 17)
        {
            return NO;
        }
        
        NSMutableCharacterSet *legalCharactersSet = [NSMutableCharacterSet hexadecimalCharacterSet];
        [legalCharactersSet addCharactersInString:@" "];
        
        if ([code rangeOfCharacterFromSet:legalCharactersSet.invertedSet].location != NSNotFound)
        {
            return NO;
        }
    }
    
    NSString *sanitizedCode = [[cheatCode componentsSeparatedByCharactersInSet:NSCharacterSet.hexadecimalCharacterSet.invertedSet] componentsJoinedByString:@""];
    int codeLength = (sanitizedCode.length / 8);
    
    ARCode code;
    memset(code.Name, 0, 128);
    memset(code.Code, 0, 128);
    memcpy(code.Name, sanitizedCode.UTF8String, MIN(128, sanitizedCode.length));
    ParseTextCode((char *)sanitizedCode.UTF8String, (int)[sanitizedCode lengthOfBytesUsingEncoding:NSUTF8StringEncoding], &code.Code[0], 128);
    code.Enabled = YES;
    code.CodeLen = codeLength;

    ARCodeCat category;
    memcpy(category.Name, sanitizedCode.UTF8String, MIN(128, sanitizedCode.length));
    category.Codes.push_back(code);

    self.cheatCodes->Categories.push_back(category);

    return YES;
}

- (void)resetCheats
{
    self.cheatCodes->Categories.clear();
    AREngine::Reset();
}

- (void)updateCheats
{
    AREngine::SetCodeFile(self.cheatCodes.get());
}

#pragma mark - Notifications -

- (void)registerForNotifications
{
    int status = notify_register_dispatch("com.apple.springboard.hasBlankedScreen", &_notifyToken, dispatch_get_main_queue(), ^(int t) {
        uint64_t state;
        int result = notify_get_state(self.notifyToken, &state);
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

- (NSURL *)dsiBIOS7URL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"dsibios7.bin"];
}

- (NSURL *)dsiBIOS9URL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"dsibios9.bin"];
}

- (NSURL *)dsiFirmwareURL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"dsifirmware.bin"];
}

- (NSURL *)dsiNANDURL
{
    return [MelonDSEmulatorBridge.coreDirectoryURL URLByAppendingPathComponent:@"dsinand.bin"];
}

@end

namespace Platform
{
    void StopEmu()
    {
        if ([MelonDSEmulatorBridge.sharedBridge isStopping])
        {
            return;
        }
        
        MelonDSEmulatorBridge.sharedBridge.stopping = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:DLTAEmulatorCore.emulationDidQuitNotification object:nil];
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
