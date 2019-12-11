//
//  AYCamera.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2019/12/11.
//  Copyright © 2019 深圳哎吖科技. All rights reserved.
//

#import "AYCamera.h"

@interface AYCamera () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    dispatch_queue_t videoProcessingQueue, audioProcessingQueue;
    dispatch_semaphore_t frameRenderingSemaphore;
}

//捕获设备，摄像头
@property (nonatomic, strong) AVCaptureDevice *camera;

//捕获设备，麦克风（音频输入）
@property (nonatomic, strong) AVCaptureDevice *microphone;

//输入设备, 使用摄像头初始化
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;

//输出设备, 输出视频数据 (CMSampleBufferRef)
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

//输入设备, 使用麦克风初始化
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

//输出设备, 输出音频数据 (CMSampleBufferRef)
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

//由他把输入输出结合在一起，并开始启动捕获设备（摄像头, 麦克风）
@property (nonatomic, strong) AVCaptureSession *session;

@end

@implementation AYCamera

- (instancetype)init {
    @throw [NSException exceptionWithName:@"init Exception" reason:@"use initWithResolution:" userInfo:nil];
}

- (instancetype)initWithResolution:(AVCaptureSessionPreset)resolution
{
    self = [super init];
    if (self) {
        [self commitInit];
        [self configVideo];
        [self configAudio];
        [self configSession:resolution];
    }
    return self;
}

- (void)commitInit{
    frameRenderingSemaphore = dispatch_semaphore_create(1);
    
    _cameraPosition = AVCaptureDevicePositionFront;

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ){
        if (device.position == AVCaptureDevicePositionFront){
            self.camera = device;
            
            if ([self.camera lockForConfiguration:nil]) {
                
                //设置为自动对焦模式
                if ([self.camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    [self.camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                }
                
                //设置为自动曝光模式
                if ([self.camera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                    [self.camera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                [self.camera unlockForConfiguration];
            }
        }
    }
    
    self.microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:nil];
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.microphone error:nil];
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    self.session = [[AVCaptureSession alloc] init];
}

- (void)configVideo{
    videoProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    [self.videoOutput setSampleBufferDelegate:self queue:videoProcessingQueue];
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
}

- (void)configAudio{
    audioProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    [self.audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
}

- (void)configSession:(AVCaptureSessionPreset)resolution {
    
    [self.session beginConfiguration];
    
    // 找一个前置相机能使用的最高分辨率
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if ([self.session canSetSessionPreset:resolution]){
        self.session.sessionPreset = resolution;
    } else {
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]){
            self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
        }else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]){
            self.session.sessionPreset = AVCaptureSessionPreset1280x720;
        }else if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]){
            self.session.sessionPreset = AVCaptureSessionPreset640x480;
        }
    }
    
    [self.session removeInput:self.videoInput];
    
    [self.session commitConfiguration];
}

- (void)startCapture{
    if (![self.session isRunning]) {
        
        if ([self.session canAddInput:self.videoInput]) {
            [self.session addInput:self.videoInput];
        }
        
        if ([self.session canAddOutput:self.videoOutput]) {
            [self.session addOutput:self.videoOutput];
        }
        
        if ([self.session canAddInput:self.audioInput]) {
            [self.session addInput:self.audioInput];
        }
        
        if ([self.session canAddOutput:self.audioOutput]) {
            [self.session addOutput:self.audioOutput];
        }
        
        [self.session startRunning];
    }
}

- (void)stopCapture{
    if ([self.session isRunning]) {
        
        [self.session removeInput:self.videoInput];
    
        [self.session removeOutput:self.videoOutput];
    
        [self.session removeInput:self.audioInput];
    
        [self.session removeOutput:self.audioOutput];
        
        [self.session stopRunning];
        
        dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(frameRenderingSemaphore);
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (output == self.videoOutput){
        if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraVideoOutput:)]) {
            [self.delegate cameraVideoOutput:sampleBuffer];
        }
        
        dispatch_semaphore_signal(frameRenderingSemaphore);

    } else if (output == self.audioOutput){
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraAudioOutput:)]) {
            [self.delegate cameraAudioOutput:sampleBuffer];
        }
    }
}

#pragma mark 设置前后相机
- (void)setCameraPosition:(AVCaptureDevicePosition)position{
    BOOL isRuning = [self.session isRunning];
    
    if (isRuning) {
        [self stopCapture];
    }
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ){
        if ( device.position == position ){
            self.camera = device;
        }
    }
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:nil];

    if (isRuning) {
        [self startCapture];
    }
    
    if ([self.camera lockForConfiguration:nil]) {

        //设置为自动对焦模式
        if ([self.camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [self.camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //设置为自动曝光模式
        if ([self.camera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.camera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        [self.camera unlockForConfiguration];
    }
    
    _cameraPosition = position;
}

#pragma mark 设置帧率
- (void)setFrameRate:(int)rate{
    if ([self.camera lockForConfiguration:nil]) {
        AVFrameRateRange *rateRange = self.camera.activeFormat.videoSupportedFrameRateRanges.lastObject;
        if (rateRange && [self.camera respondsToSelector:@selector(activeVideoMinFrameDuration)]) {
            [self.camera lockForConfiguration:nil];
            self.camera.activeVideoMinFrameDuration = CMTimeMake(1, rateRange.minFrameDuration.timescale < rate ? rateRange.minFrameDuration.timescale : rate);
            self.camera.activeVideoMaxFrameDuration = CMTimeMake(1, rateRange.minFrameDuration.timescale < rate ? rateRange.minFrameDuration.timescale : rate);
            [self.camera unlockForConfiguration];
        }
        
        [self.camera unlockForConfiguration];
    }
}

#pragma mark 设置手电筒
- (void)setTorchOn:(BOOL)torchMode{
    if ([self.camera lockForConfiguration:nil]) {
        if (torchMode) {
            if ([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
                [self.camera setTorchMode:AVCaptureTorchModeOn];
            }
        }else {
            if ([self.camera isTorchModeSupported:AVCaptureTorchModeOff]) {
                [self.camera setTorchMode:AVCaptureTorchModeOff];
            }
        }

        [self.camera unlockForConfiguration];
    }
}

#pragma mark 设置聚焦
- (void)focusAtPoint:(CGPoint)focusPoint{
    if ([self.camera lockForConfiguration:nil]) {
        //对焦模式和对焦点
        if ([self.camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.camera setFocusPointOfInterest:focusPoint];
            [self.camera setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //曝光模式和曝光点
        if ([self.camera isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.camera setExposurePointOfInterest:focusPoint];
            [self.camera setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.camera unlockForConfiguration];
    }
}
@end
