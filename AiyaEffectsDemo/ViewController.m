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
@property (nonatomic, strong) NSMutableArray *styleData;
@property (nonatomic, strong) NSArray *bigEyesAndSlimFace;

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
    self.camera.smoothSkinIntensity = 0.8;
    
    CameraView *cameraView = [[CameraView alloc]initWithFrame:self.view.frame];
    cameraView.effectData = self.effectData;
    cameraView.styleData = self.styleData;
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
    
    NSString *styleRootDirPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"FilterResources/filter"];
    NSString *styleIconRootDirPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"FilterResources/icon"];
    NSArray<NSString *> *styleFileNameArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:styleRootDirPath error:nil];
    
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
    
    //初始化滤镜资源
    _styleData = [NSMutableArray arrayWithCapacity:(styleFileNameArr.count + 1) * 3];
    
    for (NSString *styleFileName in styleFileNameArr) {
        
        NSString *stylePath = [styleRootDirPath stringByAppendingPathComponent:styleFileName];
        NSString *styleIconPath = [styleIconRootDirPath stringByAppendingPathComponent:[[styleFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:stylePath] || ![[NSFileManager defaultManager] fileExistsAtPath:styleIconPath]) {
            continue;
        }
        
        [self.styleData addObject:[UIImage imageWithContentsOfFile:styleIconPath]];
        [self.styleData addObject:[[styleFileName stringByDeletingPathExtension] substringFromIndex:2]];
        [self.styleData addObject:[UIImage imageWithContentsOfFile:stylePath]];
    }
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
    //请直接[联系客服]http://www.bbtexiao.com/site/about获取特效制作教程和大量炫酷特效
    [self.camera setEffectPath:path];
    self.camera.effectPlayCount = 0;
}

- (void)onSmoothSkinIntensityChange:(float)intensity{
    [self.camera setSmoothSkinIntensity:intensity];
    NSLog(@"SmoothSkin intensity %f",intensity);
}

- (void)onWhitenSkinIntensityChange:(float)intensity{
    [self.camera setWhitenSkinIntensity:intensity];
    NSLog(@"WhitenSkin intensity %f",intensity);
}

- (void)onBigEyesScaleChange:(float)scale{
    [self.camera setBigEyesScale:scale];
    NSLog(@"BigEye scale %f",scale);
}

- (void)onSlimFaceScaleChange:(float)scale{
    [self.camera setSlimFaceScale:scale];
    NSLog(@"SlimFace scale %f",scale);
}

- (void)onStyleClick:(UIImage *)image{
    //请直接[联系客服]http://www.bbtexiao.com/site/about获取大量滤镜(超过20个)
    [self.camera setStyle:image];
}

- (void)onStyleIntensityChange:(float)styleIntensity{
    [self.camera setStyleIntensity:styleIntensity];
    NSLog(@"style intersity %f",styleIntensity);
}

@end
