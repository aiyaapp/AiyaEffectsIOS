//
//  RecordViewController.m
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "RecordViewController.h"
#import "AYCamera.h"
#import "AYPixelBufferPreview.h"
#import "AYMediaEncoder.h"
#import <AiyaEffectSDK/AiyaEffectSDK.h>
#import "PlayerViewController.h"

typedef NS_ENUM(NSUInteger, AYMediaEncoderState) {
    AYMediaEncoderStateIdle,
    AYMediaEncoderStateRecording,
    AYMediaEncoderStateFinished,
    AYMediaEncoderStateCanceled,
};

@interface RecordViewController () <AYCameraDelegate, AYEffectHandlerDelegate>

@property (nonatomic, assign) BOOL viewAppear;
@property (nonatomic, assign) BOOL stopPreview;

@property (nonatomic, strong) AYCamera *camera;
@property (nonatomic, strong) AYPixelBufferPreview *preview;

@property (nonatomic, strong) NSLock *openGLLock;

@property (nonatomic, strong) AYEffectHandler *effectHandler;

@property (nonatomic, strong) AYMediaEncoder *encoder;
@property (nonatomic, assign) AYMediaEncoderState encoderState;

@property (nonatomic, strong) NSURL *mp4URL;

@property (nonatomic, strong) UIButton *swithCameraBt;
@property (nonatomic, strong) UIButton *startRecordBt;
@property (nonatomic, strong) UIButton *finishRecordBt;


@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;

    _openGLLock = [[NSLock alloc] init];
    
    // 相机, 录制视频分辩率
    _camera = [[AYCamera alloc] initWithResolution:AVCaptureSessionPreset1280x720];
    _camera.delegate = self;
    [_camera setFrameRate:30];

    //录制视频
    _encoder = [[AYMediaEncoder alloc]init];
    _encoderState = AYMediaEncoderStateIdle;
    
    // 相机预览UI
    _preview = [[AYPixelBufferPreview alloc] initWithFrame:self.view.frame];
    _preview.previewContentMode = AYPreivewContentModeScaleAspectFill;
    [self.view addSubview:self.preview];
    
    // 切换相机
    _swithCameraBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.swithCameraBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, 44 , 100, 50);
    [self.swithCameraBt setTitle:@"切换相机" forState:UIControlStateNormal];
    [self.swithCameraBt addTarget:self action:@selector(OnSwitchCameraBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.swithCameraBt];
    
    // 开始录制按钮
    _startRecordBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.startRecordBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height - 300, 100, 50);
    [self.startRecordBt setTitle:@"开始录制" forState:UIControlStateNormal];
    [self.startRecordBt addTarget:self action:@selector(OnStartRecordBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startRecordBt];
    
    // 结束录制按钮
    _finishRecordBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.finishRecordBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height - 300, 100, 50);
    [self.finishRecordBt setTitle:@"结束录制" forState:UIControlStateNormal];
    [self.finishRecordBt addTarget:self action:@selector(OnFinishRecordBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.finishRecordBt];
    [self.finishRecordBt setHidden:YES];
        
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark -
#pragma mark ViewController lifecycle
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [_openGLLock lock];
    
    self.viewAppear = YES;
    
    // 打开相机
    [self.camera startCapture];
    
    // 开始预览
    self.stopPreview = NO;
    
    // 页面常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [_openGLLock unlock];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    [_openGLLock lock];
    
    self.viewAppear = NO;
    
    // 结束录制
    [self.encoder cancelWriting];
    [self.startRecordBt setHidden:NO];
    [self.finishRecordBt setHidden:YES];
    
    // 关闭相机
    [self.camera stopCapture];
    
    // 结束预览
    self.stopPreview = YES;
    
    // 关闭页面常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    // 页面退到后台时必须要释放申请的GPU资源
    [self.preview releaseGLResources];
    [self.effectHandler destroy];
    self.effectHandler = nil;
    
    [_openGLLock unlock];
}

- (void)enterBackground:(NSNotification *)notifi{
    if ([self viewAppear]) {
        NSLog(@"enterBackground start");
        [self.openGLLock lock];
        
        // 结束录制
        [self.encoder cancelWriting];
        [self.startRecordBt setHidden:NO];
        [self.finishRecordBt setHidden:YES];
        
        // 关闭相机
        [self.camera stopCapture];
        
        // 结束预览
        self.stopPreview = YES;
        
        // 关闭页面常亮
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        
        // 页面退到后台时必须要释放申请的GPU资源
        [self.preview releaseGLResources];
        [self.effectHandler destroy];
        self.effectHandler = nil;
        
        [self.openGLLock unlock];
        NSLog(@"enterBackground stop");
    }
}

- (void)enterForeground:(NSNotification *)notifi{
    if ([self viewAppear]) {
        NSLog(@"enterForeground start");
        [self.openGLLock lock];
        
        self.viewAppear = YES;
        
        // 打开相机
        [self.camera startCapture];
        
        // 开始预览
        self.stopPreview = NO;
        
        // 页面常亮
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        [self.openGLLock unlock];
        NSLog(@"enterForeground stop");
    }
}

-(void)dealloc{

    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark-
#pragma mark AYEffectHandlerDelegate

- (void)playEnd {
    NSLog(@"特效播放完成");
}


#pragma mark UI event
- (void)OnStartRecordBtClick:(UIButton *)bt{
    NSString *mp4FileName = [[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingString:@".mp4"];
    self.mp4URL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:mp4FileName]];
    
    // 设置路径
    if (![self.encoder setOutputMediaURL:self.mp4URL]) {
        NSLog(@"初始化编码器失败");
        return;
    }
    
    // 初始化视频编码器
    CGAffineTransform transform;
    if (self.camera.cameraPosition == AVCaptureDevicePositionFront) {
        transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeScale(-1, 1));

    } else {
        transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeTranslation(720, 0));
    }
    
    if (![self.encoder configureVideoEncodeWithWidth:1280 height:720 videoBitRate:2*1000*1000 videoFrameRate:30 transform:transform pixelFormatType:kCVPixelFormatType_32BGRA]) {
        NSLog(@"初始化编码器失败");
        return;
    }
        
    // 初始化音频编码器
    NSDictionary *audioParamsRecommd = [self.camera.audioOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    NSUInteger sampleRate = [[audioParamsRecommd valueForKey:AVSampleRateKey] integerValue];
    NSUInteger channelCount = [[audioParamsRecommd valueForKey:AVNumberOfChannelsKey] integerValue];
    NSUInteger audioBitRate = [[audioParamsRecommd valueForKey:AVEncoderBitRateKey] integerValue];
    if (![self.encoder configureAudioEncodeWithChannelCount:channelCount == 0 ? 1 : channelCount sampleRate:sampleRate == 0 ? 44100 : sampleRate audioBitRate:audioBitRate == 0 ? 64000 : audioBitRate]) {
        NSLog(@"初始化编码器失败");
        return;
    }
    
    // 开始编码
    if (![self.encoder start]) {
        NSLog(@"初始化编码器失败");
        return;
    }
        
    _encoderState = AYMediaEncoderStateRecording;
    [self.startRecordBt setHidden:YES];
    [self.finishRecordBt setHidden:NO];
}

- (void)OnFinishRecordBtClick:(UIButton *)bt{
    
    [self.startRecordBt setHidden:YES];
    [self.finishRecordBt setHidden:YES];
    
    if (self.encoderState == AYMediaEncoderStateRecording) {
        _encoderState = AYMediaEncoderStateFinished;

        [self.encoder finishWritingWithCompletionHandler:^{
            NSLog(@"录制完成");
            
            // 切换到主线程更新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.startRecordBt setHidden:NO];
            });
            
            // 保存到相册
            NSFileManager * manager = [NSFileManager defaultManager];
            if ([manager fileExistsAtPath:self.mp4URL.path]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    PlayerViewController *playerVC = [PlayerViewController new];
                    playerVC.url = self.mp4URL;
                    [self.navigationController pushViewController:playerVC animated:true];
                });
            }
        }];
    }


}

- (void)OnSwitchCameraBtClick:(UIButton *)bt{
    if ([self.camera cameraPosition] == AVCaptureDevicePositionBack) {
        [self.camera setCameraPosition:AVCaptureDevicePositionFront];
    } else {
        [self.camera setCameraPosition:AVCaptureDevicePositionBack];
    }
}


#pragma mark-
#pragma mark AYCameraDelegate

- (void)cameraVideoOutput:(CMSampleBufferRef)sampleBuffer {
    //========== 当前为相机视频数据传输 线程==========//
    
    [self.openGLLock lock];
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    // 创建EffectHandler
    if (self.effectHandler == NULL) {
        _effectHandler = [[AYEffectHandler alloc] initWithProcessTexture:NO];
        self.effectHandler.delegate = self;
        self.effectHandler.effectPath = self.effectData[5];
    }

    // 添加特效
    if (self.camera.cameraPosition == AVCaptureDevicePositionFront) {
        self.effectHandler.rotateMode = kAYPreviewRotateRightFlipVertical;
        [self.effectHandler processWithPixelBuffer:pixelBuffer formatType:kCVPixelFormatType_32BGRA];
    }
    
    // 设置预览画面方向
    if (self.camera.cameraPosition == AVCaptureDevicePositionFront) {
        self.preview.previewRotationMode = kAYPreviewRotateRightFlipHorizontal;

    } else if (self.camera.cameraPosition == AVCaptureDevicePositionBack) {
        self.preview.previewRotationMode = kAYPreviewRotateLeft;
    }
    
    // 预览相机画面
    if (self.stopPreview == NO) {
        // 预览PixelBuffer
        [self.preview render:pixelBuffer];
    }
    
    // 写数据到Mp4文件
    if (self.encoderState == AYMediaEncoderStateRecording) {
        [self.encoder writeVideoPixelBuffer:pixelBuffer time:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    }
    
    [self.openGLLock unlock];
    
    //========== 当前为相机视频数据传输 线程==========//
}

/**
 相机回调的音频数据
 */
- (void)cameraAudioOutput:(CMSampleBufferRef)sampleBuffer{
    //========== 当前为相机音频数据传输 线程==========//
    // 写数据到Mp4文件
    if (self.encoderState == AYMediaEncoderStateRecording) {
        [self.encoder writeAudioSampleBuffer:sampleBuffer];
    }
    //========== 当前为相机音频数据传输 线程==========//
}

@end
