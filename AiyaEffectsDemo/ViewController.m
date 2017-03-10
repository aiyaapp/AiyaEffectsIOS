//
//  ViewController.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "ViewController.h"
#import "CameraView.h"
#import <AiyaCameraSDK/AiyaCamera.h>
#import <AiyaCameraSDK/AiyaLicenseManager.h>

@interface ViewController ()<CameraViewDelegate,AiyaCameraDelegate>

@property (nonatomic, assign) BOOL isViewAppear;
@property (nonatomic, strong) AiyaCamera *camera;

@property (nonatomic, strong) NSArray *effectData;
@property (nonatomic, strong) NSArray *beautifyData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _effectData = @[
        [UIImage imageNamed:@"effect"],@"原始",@"",
        [UIImage imageNamed:@"effect"],@"豹纹耳",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"baowener"],
        [UIImage imageNamed:@"effect"],@"麋鹿",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"deer"],
        [UIImage imageNamed:@"effect"],@"狗狗",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"gougou"],
        [UIImage imageNamed:@"effect"],@"小草",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"grass"],
        [UIImage imageNamed:@"effect"],@"老人",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"oldman"],
        [UIImage imageNamed:@"effect"],@"花环",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"huahuan"],
        [UIImage imageNamed:@"effect"],@"花环3D",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"huahuan3D"],
        [UIImage imageNamed:@"effect"],@"蕾丝",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"leisi"],
        [UIImage imageNamed:@"effect"],@"马镜",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"majing"],
        [UIImage imageNamed:@"effect"],@"猫耳",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"maoer"],
        [UIImage imageNamed:@"effect"],@"牛",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"niu"],
        [UIImage imageNamed:@"effect"],@"单身狗",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"saledog"],
        [UIImage imageNamed:@"effect"],@"手套",[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"shoutao"],
    ];
    _beautifyData = @[
        [UIImage imageNamed:@"beautify"],@"0",@(AIYA_BEAUTY_LEVEL_0),
        [UIImage imageNamed:@"beautify"],@"1",@(AIYA_BEAUTY_LEVEL_1),
        [UIImage imageNamed:@"beautify"],@"2",@(AIYA_BEAUTY_LEVEL_2),
        [UIImage imageNamed:@"beautify"],@"3",@(AIYA_BEAUTY_LEVEL_3),
        [UIImage imageNamed:@"beautify"],@"4",@(AIYA_BEAUTY_LEVEL_4),
        [UIImage imageNamed:@"beautify"],@"5",@(AIYA_BEAUTY_LEVEL_5),
        [UIImage imageNamed:@"beautify"],@"6",@(AIYA_BEAUTY_LEVEL_6),
        [UIImage imageNamed:@"beautify"],@"7",@(AIYA_BEAUTY_LEVEL_7),
        [UIImage imageNamed:@"beautify"],@"8",@(AIYA_BEAUTY_LEVEL_8),
        [UIImage imageNamed:@"beautify"],@"9",@(AIYA_BEAUTY_LEVEL_9),
        [UIImage imageNamed:@"beautify"],@"10",@(AIYA_BEAUTY_LEVEL_10),
        [UIImage imageNamed:@"beautify"],@"11",@(AIYA_BEAUTY_LEVEL_11),
    ];
    
    //在正式环境中填入相应的License
    [AiyaLicenseManager initLicense:@""];
    
    _camera = [[AiyaCamera alloc]initWithPreview:self.view cameraPosition:AVCaptureDevicePositionFront];
    [self.camera setSessionPreset:AVCaptureSessionPreset1280x720];
    self.camera.delegate = self;
    self.camera.mirror = YES;
    
    CameraView *cameraView = [[CameraView alloc]initWithFrame:self.view.frame];
    cameraView.effectData = self.effectData;
    cameraView.beautifyData = self.beautifyData;
    cameraView.delegate = self;
    [self.view addSubview:cameraView];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)videoCaptureOutput:(AiyaCamera *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime effectStatus:(AIYA_EFFECT_STATUS)effectStatus{
    
}

#pragma mark -
#pragma mark ViewController lifecycle
- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    self.isViewAppear= YES;
    [self.camera startCapture];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [self.camera stopCapture];
    self.isViewAppear= NO;
    [super viewWillDisappear:animated];
}

- (void)enterBackground:(NSNotification *)notifi{
    
    if ([self isViewAppear]) {
        [self.camera stopCapture];
    }
}

- (void)enterForeground:(NSNotification *)notifi{
    
    if ([self isViewAppear]) {
        [self.camera startCapture];
    }
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark-
#pragma mark ViewDelegate

- (void)onChangeCameraPosition:(AVCaptureDevicePosition)captureDevicePosition{
    
    if (self.camera.capturePosition == AVCaptureDevicePositionBack) {
        [self.camera setCapturePosition:AVCaptureDevicePositionFront];
    }else {
        [self.camera setCapturePosition:AVCaptureDevicePositionBack];
    }
}

-(void)onEffectClick:(NSString *)path{
    
    [self.camera setEffectPath:path];
    self.camera.effectPlayCount = 0;
}

- (void)onBeautyClick:(AIYA_BEAUTY_LEVEL)beautyLevel{
    
    [self.camera setBeautyLevel:beautyLevel];
}

@end
