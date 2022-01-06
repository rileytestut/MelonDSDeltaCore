//
//  MelonDSEmulatorBridge.cpp
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 1/4/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

#include "MelonDSEmulatorBridge.hpp"

//#if SWIFT_PACKAGE
//
//#import <AVFoundation/AVFoundation.h>
//#import "DeltaCoreObjC.h"
//
//#else
//
//#import <UIKit/UIKit.h> // Prevent undeclared symbols in below headers
//#import <DeltaCore/DeltaCore.h>
//#import <DeltaCore/DeltaCore-Swift.h>
//
//#if STATIC_LIBRARY
//#import "MelonDSDeltaCore-Swift.h"
//#else
//#import <MelonDSDeltaCore/MelonDSDeltaCore-Swift.h>
//#endif
//
//#endif

#include "melonDS/src/Platform.h"
#include "melonDS/src/NDS.h"
#include "melonDS/src/SPU.h"
#include "melonDS/src/GPU.h"
#include "melonDS/src/AREngine.h"

#include "melonDS/src/Config.h"

#include <memory>

#import <notify.h>
#import <pthread.h>

#import <filesystem>

namespace fs = std::__fs::filesystem;

static VoidCallback saveCallback = NULL;
static BufferCallback audioCallback = NULL;
static BufferCallback videoCallback = NULL;

static std::string coreDirectoryPath;
static std::string coreResourcesPath;

static std::shared_ptr<ARCodeFile> cheatCodes = std::make_shared<ARCodeFile>("");

static bool initialized = false;
static bool stopping = false;

static uint32_t activatedInputs = 0;
static uint32_t touchPointX = 0;
static uint32_t touchPointY = 0;

static uint8_t videoBuffer[256 * 384 * 4];

const int32_t MelonDSGameInputTouchScreenX = 4096;
const int32_t MelonDSGameInputTouchScreenY = 8192;
const int32_t MelonDSGameInputLid = 16384;

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

#pragma mark - Emulation State -

double MelonDSFrameDuration()
{
    return (1.0 / 60.0);
}

void MelonDSInitialize(const char *_Nonnull directoryPath, const char *_Nonnull resourcesPath, const char *_Nonnull bios7Path, const char *_Nonnull bios9Path, const char *_Nonnull firmwarePath)
{
    cheatCodes = std::make_shared<ARCodeFile>("");
    activatedInputs = 0;
    
    coreDirectoryPath = directoryPath;
    coreResourcesPath = resourcesPath;
    
    auto bios7Filename = fs::path(bios7Path).filename().string();
    auto bios9Filename = fs::path(bios9Path).filename().string();
    auto firmwareFilename = fs::path(firmwarePath).filename().string();
    
    // DS paths
    strncpy(Config::BIOS7Path, bios7Filename.c_str(), bios7Filename.length());
    strncpy(Config::BIOS9Path, bios9Filename.c_str(), bios9Filename.length());
    strncpy(Config::FirmwarePath, firmwareFilename.c_str(), firmwareFilename.length());
}

bool MelonDSStartEmulation(const char *_Nonnull gamePath)
{
    if (initialized)
    {
        NDS::DeInit();
    }
    else
    {
        // DS paths
//        strncpy(Config::BIOS7Path, self.bios7URL.lastPathComponent.UTF8String, self.bios7URL.lastPathComponent.length);
//        strncpy(Config::BIOS9Path, self.bios9URL.lastPathComponent.UTF8String, self.bios9URL.lastPathComponent.length);
//        strncpy(Config::FirmwarePath, self.firmwareURL.lastPathComponent.UTF8String, self.firmwareURL.lastPathComponent.length);
        
        // DSi paths
//        strncpy(Config::DSiBIOS7Path, self.dsiBIOS7URL.lastPathComponent.UTF8String, self.dsiBIOS7URL.lastPathComponent.length);
//        strncpy(Config::DSiBIOS9Path, self.dsiBIOS9URL.lastPathComponent.UTF8String, self.dsiBIOS9URL.lastPathComponent.length);
//        strncpy(Config::DSiFirmwarePath, self.dsiFirmwareURL.lastPathComponent.UTF8String, self.dsiFirmwareURL.lastPathComponent.length);
//        strncpy(Config::DSiNANDPath, self.dsiNANDURL.lastPathComponent.UTF8String, self.dsiNANDURL.lastPathComponent.length);
        
//        [self registerForNotifications];
        
        // Renderer is not deinitialized in NDS::DeInit, so initialize it only once.
        GPU::InitRenderer(0);
    }
    
//    [self prepareAudioEngine];
    
    NDS::SetConsoleType(0);

    Config::JIT_Enable = false;
    Config::JIT_FastMemory = false;
    
    NDS::Init();
    initialized = true;
        
    GPU::RenderSettings settings;
    settings.Soft_Threaded = false;

    GPU::SetRenderSettings(0, settings);
    
    auto path = fs::path(gamePath);
    if (fs::exists(path) && !fs::is_directory(path))
    {
        if (!NDS::LoadROM(gamePath, "", true))
        {
            printf("[MelonDS] Failed to load Nintendo DS ROM.\n");
        }
    }
    else
    {
        NDS::LoadBIOS();
    }
    
    stopping = false;
}

void MelonDSStopEmulation()
{
    stopping = true;
    
    NDS::Stop();
    
//    [self.audioEngine stop];
    
    // Assign to nil to prevent microphone indicator
    // staying on after returning from background.
//    self.audioEngine = nil;
}

void MelonDSPauseEmulation()
{
}

void MelonDSResumeEmulation()
{
}

#pragma mark - Game Loop -

void MelonDSRunFrame(bool processVideo)
{
    if (stopping)
    {
        return;
    }
    
    uint32_t inputs = activatedInputs;
    uint32_t inputsMask = 0xFFF; // 0b000000111111111111;
    
    uint16_t sanitizedInputs = inputsMask ^ inputs;
    NDS::SetKeyMask(sanitizedInputs);
    
    if (activatedInputs & MelonDSGameInputTouchScreenX || activatedInputs & MelonDSGameInputTouchScreenY)
    {
        NDS::TouchScreen(touchPointX, touchPointY);
    }
    else
    {
        NDS::ReleaseScreen();
    }
    
    if (activatedInputs & MelonDSGameInputLid)
    {
        NDS::SetLidClosed(true);
    }
    else if (NDS::IsLidClosed())
    {
        NDS::SetLidClosed(false);
    }
    
//    static int16_t micBuffer[735];
//    NSInteger readBytes = (NSInteger)[self.microphoneBuffer readIntoBuffer:micBuffer preferredSize:735 * sizeof(int16_t)];
//    NSInteger readFrames = readBytes / sizeof(int16_t);
//
//    if (readFrames > 0)
//    {
//        NDS::MicInputFrame(micBuffer, (int)readFrames);
//    }
    
//    if ([self isJITEnabled])
//    {
//        // Skipping frames with JIT disabled can cause graphical bugs,
//        // so limit frame skip to devices that support JIT (for now).
//        NDS::SetSkipFrame(!processVideo);
//    }
    
    NDS::RunFrame();
    
    static int16_t buffer[0x1000];
    u32 availableBytes = SPU::GetOutputSize();
    availableBytes = std::max(availableBytes, (u32)(sizeof(buffer) / (2 * sizeof(int16_t))));
       
    int samples = SPU::ReadOutput(buffer, availableBytes);
    audioCallback((unsigned char *)buffer, samples * 4);
    
    if (processVideo)
    {
        int screenBufferSize = 256 * 192 * 4;
        
        memcpy(videoBuffer, GPU::Framebuffer[GPU::FrontBuffer][0], screenBufferSize);
        memcpy(videoBuffer + screenBufferSize, GPU::Framebuffer[GPU::FrontBuffer][1], screenBufferSize);
        
        videoCallback(videoBuffer, screenBufferSize * 2);
    }
}

#pragma mark - Inputs -

void MelonDSActivateInput(int input, double value)
{
    activatedInputs |= (uint32_t)input;
        
    switch (input)
    {
    case MelonDSGameInputTouchScreenX:
        touchPointX = value * (256 - 1);
        break;
        
    case MelonDSGameInputTouchScreenY:
        touchPointY = value * (192 - 1);
        break;
            
    default: break;
    }
}

void MelonDSDeactivateInput(int input)
{
    activatedInputs &= ~((uint32_t)input);
        
    switch (input)
    {
        case MelonDSGameInputTouchScreenX:
            touchPointX = 0;
            break;
            
        case MelonDSGameInputTouchScreenY:
            touchPointY = 0;
            break;
            
        default: break;
    }
}

void MelonDSResetInputs()
{
    activatedInputs = 0;
    touchPointX = 0;
    touchPointY = 0;
}

#pragma mark - Save States -

void MelonDSSaveSaveState(const char *_Nonnull saveStatePath)
{
    
}

void MelonDSLoadSaveState(const char *_Nonnull saveStatePath)
{
    
}

#pragma mark - Game Saves -

void MelonDSSaveGameSave(const char *_Nonnull gameSavePath)
{
    
}

void MelonDSLoadGameSave(const char *_Nonnull gameSavePath)
{
    
}

#pragma mark - Cheats -

bool MelonDSAddCheatCode(const char *_Nonnull cheatCode, const char *_Nonnull type)
{
    return true;
}

void MelonDSResetCheats()
{
}

void MelonDSUpdateCheats()
{
}

#pragma mark - Callbacks -

void MelonDSSetAudioCallback(BufferCallback callback)
{
    audioCallback = callback;
}

void MelonDSSetVideoCallback(BufferCallback callback)
{
    videoCallback = callback;
}

void MelonDSSetSaveCallback(VoidCallback callback)
{
    saveCallback = callback;
}

namespace Platform
{
    void StopEmu()
    {
        if (stopping)
        {
            return;
        }
        
        stopping = true;
//        [[NSNotificationCenter defaultCenter] postNotificationName:DLTAEmulatorCore.emulationDidQuitNotification object:nil];
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
        fs::path filePath;
        
        if (std::string(path).find("melondsfastmem") != std::string::npos || std::string(path).find("firmware.bin.bak") != std::string::npos)
        {
            filePath = fs::path(coreDirectoryPath);
        }
        else
        {
            filePath = fs::path(coreResourcesPath);
        }
        
        filePath.append(path);
        
        return OpenFile(filePath.c_str(), mode);
    }
    
    FILE* OpenDataFile(const char* path)
    {
        auto resourceName = fs::path(path).stem();
        auto extension = fs::path(path).extension();
        
        auto filePath = fs::path(coreResourcesPath);
        filePath.append(resourceName.c_str());
        filePath.replace_extension(extension);
        
        return OpenFile(filePath.c_str(), "rb");
    }
    
    Thread *Thread_Create(void (*func)())
    {
        return NULL;
//        NSThread *thread = [[NSThread alloc] initWithBlock:^{
//            func();
//        }];
//
//        thread.name = @"MelonDS - Rendering";
//        thread.qualityOfService = NSQualityOfServiceUserInitiated;
//
//        [thread start];
//
//        return (Thread *)CFBridgingRetain(thread);
    }
    
    void Thread_Free(Thread *thread)
    {
//        NSThread *nsThread = (NSThread *)CFBridgingRelease(thread);
//        [nsThread cancel];
    }
    
    void Thread_Wait(Thread *thread)
    {
//        NSThread *nsThread = (__bridge NSThread *)thread;
//        while (nsThread.isExecuting)
//        {
//            continue;
//        }
    }
    
    Semaphore *Semaphore_Create()
    {
//        dispatch_semaphore_t dispatchSemaphore = dispatch_semaphore_create(0);
//        return (Semaphore *)CFBridgingRetain(dispatchSemaphore);
    }
    
    void Semaphore_Free(Semaphore *semaphore)
    {
//        CFRelease(semaphore);
    }
    
    void Semaphore_Reset(Semaphore *semaphore)
    {
//        dispatch_semaphore_t dispatchSemaphore = (__bridge dispatch_semaphore_t)semaphore;
//        while (dispatch_semaphore_wait(dispatchSemaphore, DISPATCH_TIME_NOW) == 0)
//        {
//            continue;
//        }
    }
    
    void Semaphore_Wait(Semaphore *semaphore)
    {
//        dispatch_semaphore_t dispatchSemaphore = (__bridge dispatch_semaphore_t)semaphore;
//        dispatch_semaphore_wait(dispatchSemaphore, DISPATCH_TIME_FOREVER);
    }

    void Semaphore_Post(Semaphore *semaphore, int count)
    {
//        dispatch_semaphore_t dispatchSemaphore = (__bridge dispatch_semaphore_t)semaphore;
//        for (int i = 0; i < count; i++)
//        {
//            dispatch_semaphore_signal(dispatchSemaphore);
//        }
    }

    Mutex *Mutex_Create()
    {
        // NSLock is too slow for real-time audio, so use pthread_mutex_t directly.
        
        pthread_mutex_t *mutex = (pthread_mutex_t *)malloc(sizeof(pthread_mutex_t));
        pthread_mutex_init(mutex, NULL);
        return (Mutex *)mutex;
    }

    void Mutex_Free(Mutex *m)
    {
        pthread_mutex_t *mutex = (pthread_mutex_t *)m;
        pthread_mutex_destroy(mutex);
        free(mutex);
    }

    void Mutex_Lock(Mutex *m)
    {
        pthread_mutex_t *mutex = (pthread_mutex_t *)m;
        pthread_mutex_lock(mutex);
    }

    void Mutex_Unlock(Mutex *m)
    {
        pthread_mutex_t *mutex = (pthread_mutex_t *)m;
        pthread_mutex_unlock(mutex);
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

    void Mic_Prepare()
    {
//        if (![MelonDSEmulatorBridge.sharedBridge isMicrophoneEnabled] || [MelonDSEmulatorBridge.sharedBridge.audioEngine isRunning])
//        {
//            return;
//        }
//        
//        NSError *error = nil;
//        if (![MelonDSEmulatorBridge.sharedBridge.audioEngine startAndReturnError:&error])
//        {
//            NSLog(@"Failed to start listening to microphone. %@", error);
//        }
    }
}
