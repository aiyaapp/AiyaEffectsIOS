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

@property (nonatomic, strong) NSMutableArray *effectData;
@property (nonatomic, strong) NSArray *beautifyData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initResourceData];
    
    //在正式环境中填入相应的License
    [AiyaLicenseManager initLicense:@"704705f35759"];
    
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


/**
 初始化资源数据
 */
- (void)initResourceData{
    NSString *effectRootDirPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"EffectResources"];
    NSArray<NSString *> *effectDirNameArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:effectRootDirPath error:nil];
    
    //初始化特效资源
    _effectData = [NSMutableArray arrayWithCapacity:(effectDirNameArr.count + 1) * 3];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"effect"],@"原始",@""]];
    
    for (NSString *effectDirName in effectDirNameArr) {
        
        NSString *path = [effectRootDirPath stringByAppendingPathComponent:[effectDirName stringByAppendingPathComponent:@"meta.json"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            continue;
        }
        NSData *jsonData = [NSData dataWithContentsOfFile:path];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        
        [self.effectData addObject:[UIImage imageNamed:@"effect"]];
        [self.effectData addObject:dic[@"name"]];
        [self.effectData addObject:path];
    }
    
    //初始化美颜资源
    _beautifyData = @[
                      [UIImage imageNamed:@"beautify"],@"美颜0",@(AIYA_BEAUTY_TYPE_0),
                      [UIImage imageNamed:@"beautify"],@"美颜1",@(AIYA_BEAUTY_TYPE_1),
                      [UIImage imageNamed:@"beautify"],@"美颜4",@(AIYA_BEAUTY_TYPE_4),
                      [UIImage imageNamed:@"beautify"],@"美颜5",@(AIYA_BEAUTY_TYPE_5),
                      ];
}

#pragma mark -
#pragma mark AiyaCameraDelegate
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
