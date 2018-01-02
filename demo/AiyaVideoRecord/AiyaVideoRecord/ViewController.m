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
    
    //数据处理
    self.dataProcess = [[CameraDataProcess alloc] init];
    self.dataProcess.mirror = YES;
    self.dataProcess.delegate = self;
    
    //相机
    self.camera = [[Camera alloc] init];
    self.camera.delegate = self;
    [self.camera startCapture];
    [self.camera setRate:30];
    
    // 开始录制按钮
    UIButton *startRecordBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    startRecordBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height - 300, 100, 100);
    [startRecordBt setTitle:@"开始录制" forState:UIControlStateNormal];
    [startRecordBt addTarget:self action:@selector(OnStartRecordBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordBt];
    
    // 拍照按钮
    UIButton *snapshootBt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    snapshootBt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height - 200, 100, 100);
    [snapshootBt setTitle:@"拍照" forState:UIControlStateNormal];
    [snapshootBt addTarget:self action:@selector(OnSnapshootBtClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:snapshootBt];
}

- (void)OnStartRecordBtClick:(UIButton *)bt{
    NSString *mp4FileName = [[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingString:@".mp4"];
    NSURL *mp4URL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:mp4FileName]];
    self.writer.outputURL = mp4URL;
    
    self.writeData = YES;
    [bt setHidden:YES];
    
    // 5秒之后视频录制完成
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.writer finishWritingWithCompletionHandler:^{
            NSLog(@"录制完成");
            self.writeData = NO;
            [bt setHidden:NO];

            UISaveVideoAtPathToSavedPhotosAlbum(self.writer.outputURL.path, nil, nil, nil);
        }];
    });
}

- (void)OnSnapshootBtClick:(UIButton *)bt{
    self.snapshoot = YES;
}

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

    // 预览
    [self.preview render:CMSampleBufferGetImageBuffer(bgraSampleBuffer)];
    
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

@end
