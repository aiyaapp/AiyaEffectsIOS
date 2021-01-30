//
//  DecoderAndEncoderViewController.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/25.
//  Copyright © 2021 深圳哎吖科技. All rights reserved.
//

#import "DecoderAndEncoderViewController.h"
#import "AYPixelBufferPreview.h"
#import "AYMediaDecoder.h"
#import "AYMediaEncoder.h"
#import "PlayerViewController.h"

@interface DecoderAndEncoderViewController () <AYMediaDecoderDelegate>

@property (nonatomic, assign) BOOL viewAppear;
@property (nonatomic, assign) BOOL stopPreview;

@property (nonatomic, strong) AYPixelBufferPreview *preview;

@property (nonatomic, strong) NSLock *openGLLock;

@property (nonatomic, strong) UIButton *startBt;

@property (nonatomic, strong) NSURL *decoderInputURL;
@property (nonatomic, assign) BOOL decoderVideoEOS;
@property (nonatomic, assign) BOOL decoderAudioEOS;
@property (nonatomic, strong) AYMediaDecoder *decoder;

@property (nonatomic, strong) NSURL *encoderOutputURL;
@property (nonatomic, assign) BOOL videoEncoderConfigResult;
@property (nonatomic, assign) BOOL audioEncoderConfigResult;
@property (nonatomic, strong) AYMediaEncoder *encoder;

@end

@implementation DecoderAndEncoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;

    _openGLLock = [[NSLock alloc] init];
    
    // 画面预览UI
    _preview = [[AYPixelBufferPreview alloc] initWithFrame:self.view.frame];
    _preview.previewContentMode = AYPreivewContentModeScaleAspectFill;
    [self.view addSubview:self.preview];
    
    
    // 开始录制按钮
    _startBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.startBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height - 300, 100, 50);
    [self.startBt setTitle:@"开始转码" forState:UIControlStateNormal];
    [self.startBt addTarget:self action:@selector(OnStartBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startBt];
        
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark -
#pragma mark ViewController lifecycle
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [_openGLLock lock];
    
    self.viewAppear = YES;

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
    
    // 结束预览
    self.stopPreview = YES;
    
    // 关闭页面常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    // 页面退到后台时必须要释放申请的GPU资源
    [self.decoder cancelReading];
    [self.encoder cancelWriting];
    [self.preview releaseGLResources];
    self.startBt.hidden = NO;

    [_openGLLock unlock];
}

- (void)enterBackground:(NSNotification *)notifi{
    if ([self viewAppear]) {
        NSLog(@"enterBackground start");
        [self.openGLLock lock];

        // 结束预览
        self.stopPreview = YES;
        
        // 关闭页面常亮
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        
        // 页面退到后台时必须要释放申请的GPU资源
        [self.decoder cancelReading];
        [self.encoder cancelWriting];
        [self.preview releaseGLResources];
        self.startBt.hidden = NO;

        [self.openGLLock unlock];
        NSLog(@"enterBackground stop");
    }
}

- (void)enterForeground:(NSNotification *)notifi{
    if ([self viewAppear]) {
        NSLog(@"enterForeground start");
        [self.openGLLock lock];
        
        self.viewAppear = YES;

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


#pragma mark UI event
- (void)OnStartBtClick:(UIButton *)bt{
    self.startBt.hidden = YES;
    
    // 创建解码器
    self.decoderVideoEOS = NO;
    self.decoderAudioEOS = NO;
    self.decoderInputURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4" inDirectory:@"VideoResources"]];
    self.decoder = [AYMediaDecoder new];
    self.decoder.delegate = self;
    
    // 创建编码器
    self.videoEncoderConfigResult = NO;
    self.audioEncoderConfigResult = NO;
    self.encoderOutputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingString:@".mp4"]]];
    self.encoder = [[AYMediaEncoder alloc]init];

    // 通过本地文件创建解码器
    __weak typeof(self) ws = self;
    [self.decoder setOutputMediaURL:self.decoderInputURL completion:^(bool success) {
        if (success) {
            
            // 创建编码器
            if (![ws.encoder setOutputMediaURL:ws.encoderOutputURL]) {
                NSLog(@"创建编码器失败");
                return;
            }
            
            // 开始解码音视频信息
            [ws.decoder configureVideoDecoder];
            [ws.decoder configureAudioDecoder];
            
        } else {
            NSLog(@"创建解码器失败");
        }
    }];
}

- (void)decoderOutputVideoFormatWithWidth:(NSUInteger)width height:(NSUInteger)height videoFrameRate:(NSUInteger)videoFrameRate transform:(CGAffineTransform)transform {
        
    // 解码视频信息完成
    if (width > 0 && height > 0 && videoFrameRate > 0) {
        
        // 配置编码器
        if ([self.encoder configureVideoEncoderWithWidth:width height:height videoBitRate:2*1000*1000 videoFrameRate:videoFrameRate transform:transform pixelFormatType:kCVPixelFormatType_32BGRA]) {
            
            self.videoEncoderConfigResult = true;
            if (self.videoEncoderConfigResult && self.audioEncoderConfigResult) {
                
                // 开始编解码转换
                [self.encoder start];
                [self.decoder start];
            }
            
        } else {
            NSLog(@"配置视频编码器失败");
        }
    } else {
        NSLog(@"解码视频信息失败");
    }

    // 设置视频画面预览方向
    switch ([AYMediaDecoder preferredTransformToRotation:transform]) {
        case 0:
            [_preview setPreviewRotationMode:kAYPreviewNoRotation];
            break;
        case 90:
            [_preview setPreviewRotationMode:kAYPreviewRotateLeft];
            break;
        case 180:
            [_preview setPreviewRotationMode:kAYPreviewRotate180];
            break;
        case 270:
            [_preview setPreviewRotationMode:kAYPreviewRotateRight];
            break;
    }

}

- (void)decoderOutputAudioFormatWithChannelCount:(NSUInteger)channelCount sampleRate:(NSUInteger)sampleRate {
    
    // 解码音频信息完成
    if (channelCount > 0 && sampleRate > 0) {
        
        // 配置编码器
        if ([self.encoder configureAudioEncoderWithChannelCount:channelCount sampleRate:sampleRate audioBitRate:64000]) {

            self.audioEncoderConfigResult = true;
            if (self.videoEncoderConfigResult && self.audioEncoderConfigResult) {
                
                // 开始编解码转换
                [self.encoder start];
                [self.decoder start];
            }
            
        } else {
            NSLog(@"配置音频编码器失败");
        }
        
    } else {
        NSLog(@"解码音频信息失败");
    }

}

- (void)decoderVideoOutput:(CMSampleBufferRef)sampleBuffer {
    //========== 当前为视频解码 线程==========//
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    // 视频编码
    [self.encoder writeVideoPixelBuffer:pixelBuffer time:pts];

    // 渲染画面
    [self.preview render: pixelBuffer];
    
    //========== 当前为视频解码 线程==========//
}

- (void)decoderAudioOutput:(CMSampleBufferRef)sampleBuffer {
    //========== 当前为音频解码 线程==========//

    // 音频编码
    [self.encoder writeAudioSampleBuffer:sampleBuffer];
    
    //========== 当前为音频解码 线程==========//
}

- (void)decoderVideoEOS:(BOOL)success {
    NSLog(@"解码视频完成");
    self.decoderVideoEOS = true;
    
    if (self.decoderVideoEOS && self.decoderAudioEOS) {
        __weak typeof(self) ws = self;
        [self.encoder finishWritingWithCompletionHandler:^{
            [ws playMedia];
        }];
    }
}

- (void)decoderAudioEOS:(BOOL)success {
    NSLog(@"解码音频完成");
    self.decoderAudioEOS = true;
    
    if (self.decoderVideoEOS && self.decoderAudioEOS) {
        __weak typeof(self) ws = self;
        [self.encoder finishWritingWithCompletionHandler:^{
            [ws playMedia];
        }];
    }
}

- (void)playMedia {
    // 进行播放
    NSFileManager * manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.encoderOutputURL.path]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            PlayerViewController *playerVC = [PlayerViewController new];
            playerVC.url = self.encoderOutputURL;
            [self.navigationController pushViewController:playerVC animated:true];
        });
    }
}
@end
