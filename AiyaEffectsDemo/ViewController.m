//
//  ViewController.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "ViewController.h"
#import "CameraView.h"
#import <AiyaCameraSDK/AiyaCameraSDK.h>

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
        [UIImage imageNamed:@"beautify"],@"美颜0",@(AIYA_BEAUTY_TYPE_0),
        [UIImage imageNamed:@"beautify"],@"美颜1",@(AIYA_BEAUTY_TYPE_1),
        [UIImage imageNamed:@"beautify"],@"美颜4",@(AIYA_BEAUTY_TYPE_4),
        [UIImage imageNamed:@"beautify"],@"美颜5",@(AIYA_BEAUTY_TYPE_5),
    ];
    
    //在正式环境中填入相应的License
    [AiyaLicenseManager initLicense:@"" appKey:@""];
    
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

- (void)onBeautyTypeClick:(AIYA_BEAUTY_TYPE)beautyType{
    [self.camera setBeautyType:beautyType];
}

- (void)onBeautyLevelChange:(AIYA_BEAUTY_LEVEL)beautyLevel{
    [self.camera setBeautyLevel:beautyLevel];
}

@end
