//
//  ViewController.m
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import "Camera.h"
#import "CameraDataProcess.h"
#import "Preview.h"
#import "MediaWriter.h"
#import <AiyaEffectSDK/AiyaEffectSDK.h>

@interface ViewController () <CameraDelegate, CameraDataProcessDelegate>

@property (nonatomic, strong) Camera *camera;
@property (nonatomic, strong) CameraDataProcess *dataProcess;
@property (nonatomic, strong) Preview *preview;
@property (nonatomic, strong) MediaWriter *writer;
@property (nonatomic, strong) AYEffectHandler *handler;

@property (nonatomic, assign) BOOL writeData;
@property (nonatomic, assign) BOOL snapshoot;

@property (nonatomic, strong) UIButton *swithCameraBt;

@property (nonatomic, strong) UIButton *startRecordBt;
@property (nonatomic, strong) UIButton *finishRecordBt;

@property (nonatomic, assign) BOOL isViewAppear;
@property (nonatomic, assign) BOOL stopOpenGL;

@property (strong, nonatomic) CALayer *focusBoxLayer;
@property (strong, nonatomic) CAAnimation *focusBoxAnimation;

@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // license state notification
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(licenseMessage:) name:AiyaLicenseNotification object:nil];
    
    // init license
    [AYLicenseManager initLicense:@"0244e715ce48440ea4ddb08054d9066b"];
    
    //录制视频
    self.writer = [[MediaWriter alloc]init];
    
    //预览
    self.preview = [[Preview alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.preview];
    
    // 添加点按手势，点按时聚焦
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.preview addGestureRecognizer:tapGesture];
    
    //数据处理
    self.dataProcess = [[CameraDataProcess alloc] init];
    self.dataProcess.mirror = YES;
    self.dataProcess.delegate = self;
    
    //相机
    self.camera = [[Camera alloc] init];
    self.camera.delegate = self;
    [self.camera setRate:30];
    self.cameraPosition = AVCaptureDevicePositionFront;
    
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
    
    // 拍照按钮
    UIButton *snapshootBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    snapshootBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height - 200, 100, 50);
    [snapshootBt setTitle:@"拍照" forState:UIControlStateNormal];
    [snapshootBt addTarget:self action:@selector(OnSnapshootBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:snapshootBt];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark UI event
- (void)OnStartRecordBtClick:(UIButton *)bt{
    NSString *mp4FileName = [[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingString:@".mp4"];
    NSURL *mp4URL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:mp4FileName]];
    self.writer.outputURL = mp4URL;
    
    self.writeData = YES;
    
    [self.startRecordBt setHidden:YES];
    [self.finishRecordBt setHidden:NO];
}

- (void)OnFinishRecordBtClick:(UIButton *)bt{
    
    [self.startRecordBt setHidden:YES];
    [self.finishRecordBt setHidden:YES];
    
    [self finishRecordVideo];
}

- (void)OnSnapshootBtClick:(UIButton *)bt{
    self.snapshoot = YES;
}

#pragma mark license
- (void)licenseMessage:(NSNotification *)notifi{
    
    AiyaLicenseResult result = [notifi.userInfo[AiyaLicenseNotificationUserInfoKey] integerValue];
    switch (result) {
        case AiyaLicenseSuccess:
            NSLog(@"License 验证成功");
            break;
        case AiyaLicenseFail:
            NSLog(@"License 验证失败");
            break;
    }
}

#pragma mark CameraDelegate
/**
 相机回调的视频数据
 */
- (void)cameraVideoOutput:(CMSampleBufferRef)sampleBuffer{
    
    // 处理数据
    CMSampleBufferRef bgraSampleBuffer = [self.dataProcess process:sampleBuffer];

    if (self.stopOpenGL) {
        CMSampleBufferInvalidate(bgraSampleBuffer);
        CFRelease(bgraSampleBuffer);
        bgraSampleBuffer = NULL;
        return;
    }
    
    // 预览
    [self.preview render:CMSampleBufferGetImageBuffer(bgraSampleBuffer)];
    
    if (self.stopOpenGL) {
        CMSampleBufferInvalidate(bgraSampleBuffer);
        CFRelease(bgraSampleBuffer);
        bgraSampleBuffer = NULL;
        return;
    }
    
    // 写数据到Mp4文件
    if (self.writeData) {
        [self.writer writeVideoPixelBuffer:CMSampleBufferGetImageBuffer(bgraSampleBuffer) time:CMSampleBufferGetPresentationTimeStamp(bgraSampleBuffer)];
    }
    
    // 保存屏幕快照
    if (self.snapshoot) {
        self.snapshoot = NO;
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(bgraSampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        //从 CVImageBufferRef 取得影像的细部信息
        uint8_t *base;
        size_t width, height, bytesPerRow;
        base = CVPixelBufferGetBaseAddress(pixelBuffer);
        width = CVPixelBufferGetWidth(pixelBuffer);
        height = CVPixelBufferGetHeight(pixelBuffer);
        bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        //利用取得影像细部信息格式化 CGContextRef
        CGColorSpaceRef colorSpace;
        CGContextRef cgContext;
        colorSpace = CGColorSpaceCreateDeviceRGB();
        cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        
        // 将 CGContextRef 转换成 CGImageRef
        CGImageRef cgImage;
        cgImage = CGBitmapContextCreateImage(cgContext);
        CGContextRelease(cgContext);
        
        // 将 CGImageRef 转换成 UIImage
        UIImage *image;
        image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];// 旋转了90
        CGImageRelease(cgImage);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

        // 保存到相册
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
    // 释放资源
    CMSampleBufferInvalidate(bgraSampleBuffer);
    CFRelease(bgraSampleBuffer);
    bgraSampleBuffer = NULL;

}

/**
 相机回调的音频数据
 */
- (void)cameraAudioOutput:(CMSampleBufferRef)sampleBuffer{
    
    //写数据到Mp4文件
    if (self.writeData) {
        [self.writer writeAudioSampleBuffer:sampleBuffer];
    }
}

/**
 聚焦
 */
-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.preview];
    
    CGPoint pointOfInterest;
    if (self.dataProcess.mirror) { // 相机的输出画面是横的. 屏幕的右上角在相机中是左上, 屏幕的左下角在相机中是右下, 前置画面做了镜像. 如果是横屏显示此处要修改
        pointOfInterest = CGPointMake(point.y / self.preview.bounds.size.height, point.x / self.preview.bounds.size.width);
    } else {
        pointOfInterest = CGPointMake(point.y / self.preview.bounds.size.height, 1.0f - point.x / self.preview.bounds.size.width);
    }
    
    NSLog(@"focusAtPoint x:%f y:%f",pointOfInterest.x, pointOfInterest.y);
    
    [self.camera focusAtPoint:pointOfInterest];
    [self showFocusBox:point];
}

- (void)showFocusBox:(CGPoint)point{
    if(!self.focusBoxLayer) {
        CALayer *focusBoxLayer = [[CALayer alloc] init];
        focusBoxLayer.cornerRadius = 3.0f;
        focusBoxLayer.bounds = CGRectMake(0.0f, 0.0f, 70, 70);
        focusBoxLayer.borderWidth = 1.0f;
        focusBoxLayer.borderColor = [[UIColor yellowColor] CGColor];
        focusBoxLayer.opacity = 0.0f;
        [self.view.layer addSublayer:focusBoxLayer];
        self.focusBoxLayer = focusBoxLayer;
    }
    
    if(!self.focusBoxAnimation) {
        CABasicAnimation *focusBoxAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        focusBoxAnimation.duration = 1;
        focusBoxAnimation.autoreverses = NO;
        focusBoxAnimation.repeatCount = 0.0;
        focusBoxAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        focusBoxAnimation.toValue = [NSNumber numberWithFloat:0.0];
        self.focusBoxAnimation = focusBoxAnimation;
    }
    
    if(self.focusBoxLayer) {
        [self.focusBoxLayer removeAllAnimations];
        
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        self.focusBoxLayer.position = point;
        [CATransaction commit];
    }
    
    if(self.focusBoxAnimation) {
        [self.focusBoxLayer addAnimation:self.focusBoxAnimation forKey:@"animateOpacity"];
    }
}

/**
 切换相机
 */
- (void)OnSwitchCameraBtClick:(UIButton *)bt{
    switch (self.cameraPosition) {
        case AVCaptureDevicePositionUnspecified:
            [self.camera setCameraPosition:AVCaptureDevicePositionFront];
            self.cameraPosition = AVCaptureDevicePositionFront;
            self.dataProcess.mirror = YES;
            break;
        case AVCaptureDevicePositionFront: {
            [self.camera setCameraPosition:AVCaptureDevicePositionBack];
            self.cameraPosition = AVCaptureDevicePositionBack;
            self.dataProcess.mirror = NO;
        }
            break;
        case AVCaptureDevicePositionBack: {
            [self.camera setCameraPosition:AVCaptureDevicePositionFront];
            self.cameraPosition = AVCaptureDevicePositionFront;
            self.dataProcess.mirror = YES;
        }
            break;
    }
}

#pragma mark CameraDataProcessDelegate
/**
 处理回调的纹理数据
 
 @param texture 纹理数据
 */
- (GLuint)cameraDataProcessWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height{
    
    if (!self.handler) {
        self.handler = [[AYEffectHandler alloc] init];
        self.handler.verticalFlip = YES;
        [self.handler setBigEye:0.2];
        [self.handler setSlimFace:0.2];
        [self.handler setSmooth:1];
        [self.handler setEffectPath:[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"grass"]];
    }
    
    [self.handler processWithTexture:texture width:width height:height];
    
    return texture;
}

#pragma mark RecordControl

- (void)finishRecordVideo{
    if (self.writeData) {
        self.writeData = NO;

        [self.writer finishWritingWithCompletionHandler:^{
            NSLog(@"录制完成");
            
            // 切换到主线程更新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.startRecordBt setHidden:NO];
            });
            
            // 保存到相册
            UISaveVideoAtPathToSavedPhotosAlbum(self.writer.outputURL.path, nil, nil, nil);
        }];
    }
}

- (void)cancelRecordVideo{
    if (self.writeData) {
        self.writeData = NO;
        
        NSLog(@"取消录制");
        [self.writer cancelWriting];
        
        [self.startRecordBt setHidden:NO];
        [self.finishRecordBt setHidden:YES];
    }
}

#pragma mark - viewControllerLifeCycle
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.isViewAppear= YES;
    
    [self.camera startCapture];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.stopOpenGL = NO;
    self.preview.renderSuspended = NO;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.isViewAppear= NO;
    
    [self.camera stopCapture];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    self.stopOpenGL = YES;
    self.preview.renderSuspended = YES;
}

- (void)enterBackground:(NSNotification *)notifi{
    if ([self isViewAppear]) {
        
        [self.camera stopCapture];
        
        [self cancelRecordVideo];
        
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        self.stopOpenGL = YES;
        self.preview.renderSuspended = YES;
    }
}

- (void)enterForeground:(NSNotification *)notifi{
    if ([self isViewAppear]) {
    
        [self.camera startCapture];
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        self.stopOpenGL = NO;
        self.preview.renderSuspended = NO;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
