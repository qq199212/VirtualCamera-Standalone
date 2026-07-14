#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <objc/runtime.h>
#import "substrate.h"

static AVAssetReader *assetReader = nil;
static AVAssetReaderTrackOutput *videoTrackOutput = nil;
static AVAssetReaderTrackOutput *audioTrackOutput = nil;
static dispatch_once_t setupToken;

static void setupAssetReader() {
    dispatch_once(&setupToken, ^{
        NSString *videoPath = @"/var/mobile/Library/virtualcam.mp4";
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        
        NSError *error = nil;
        assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
        if (error || !assetReader) return;
        
        // 视频轨道
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (videoTrack) {
            videoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:nil];
            videoTrackOutput.alwaysCopiesSampleData = NO;
            [assetReader addOutput:videoTrackOutput];
        }
        
        // 音频轨道
        AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if (audioTrack) {
            audioTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:nil];
            audioTrackOutput.alwaysCopiesSampleData = NO;
            [assetReader addOutput:audioTrackOutput];
        }
        
        [assetReader startReading];
    });
}

// 保存原方法实现
static void (*orig_setVideoDelegate)(id, SEL, id, dispatch_queue_t);
static void (*orig_setAudioDelegate)(id, SEL, id, dispatch_queue_t);
static void (*orig_captureOutput)(id, SEL, AVCaptureOutput *, CMSampleBufferRef, AVCaptureConnection *);

// 替换后的视频代理设置方法
static void replaced_setVideoDelegate(id self, SEL _cmd, id delegate, dispatch_queue_t queue) {
    setupAssetReader();
    orig_setVideoDelegate(self, _cmd, delegate, queue);
}

// 替换后的音频代理设置方法
static void replaced_setAudioDelegate(id self, SEL _cmd, id delegate, dispatch_queue_t queue) {
    setupAssetReader();
    orig_setAudioDelegate(self, _cmd, delegate, queue);
}

// 替换后的样本输出方法
static void replaced_captureOutput(id self, SEL _cmd, AVCaptureOutput *output, CMSampleBufferRef sampleBuffer, AVCaptureConnection *connection) {
    setupAssetReader();
    
    if (!assetReader || assetReader.status != AVAssetReaderStatusReading) {
        [assetReader cancelReading];
        [assetReader startReading];
    }
    
    if ([output isKindOfClass:NSClassFromString(@"AVCaptureVideoDataOutput")]) {
        if (videoTrackOutput) {
            CMSampleBufferRef newSample = [videoTrackOutput copyNextSampleBuffer];
            if (newSample) {
                orig_captureOutput(self, _cmd, output, newSample, connection);
                CFRelease(newSample);
                return;
            }
        }
    } else if ([output isKindOfClass:NSClassFromString(@"AVCaptureAudioDataOutput")]) {
        if (audioTrackOutput) {
            CMSampleBufferRef newSample = [audioTrackOutput copyNextSampleBuffer];
            if (newSample) {
                orig_captureOutput(self, _cmd, output, newSample, connection);
                CFRelease(newSample);
                return;
            }
        }
    }
    
    orig_captureOutput(self, _cmd, output, sampleBuffer, connection);
}

// 插件加载时自动执行hook
__attribute__((constructor)) static void vcam_init() {
    Class videoCls = objc_getClass("AVCaptureVideoDataOutput");
    Class audioCls = objc_getClass("AVCaptureAudioDataOutput");
    Class nsobjCls = objc_getClass("NSObject");
    
    MSHookMessageEx(videoCls, @selector(setSampleBufferDelegate:queue:), (IMP)replaced_setVideoDelegate, (IMP *)&orig_setVideoDelegate);
    MSHookMessageEx(audioCls, @selector(setSampleBufferDelegate:queue:), (IMP)replaced_setAudioDelegate, (IMP *)&orig_setAudioDelegate);
    MSHookMessageEx(nsobjCls, @selector(captureOutput:didOutputSampleBuffer:fromConnection:), (IMP)replaced_captureOutput, (IMP *)&orig_captureOutput);
}
