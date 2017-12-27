//
//  ViewController.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "ViewController.h"
#import "CameraView.h"
#import "AiyaEffectFilter.h"
#import <GPUImage/GPUImage.h>
#import <AiyaEffectSDK/AiyaEffectSDK.h>

@interface ViewController () <CameraViewDelegate>{
    GPUImageVideoCamera *_videoCamera;
    AiyaEffectFilter *_effectFilter;
    GPUImageView *_cameraPreview;
}

@property (nonatomic, assign) BOOL isViewAppear;

@property (nonatomic, strong) NSMutableArray *effectData;
@property (nonatomic, strong) NSMutableArray *styleData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // license state notification
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(licenseMessage:) name:AiyaLicenseNotification object:nil];
    
    // render state notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aiyaMessage:) name:AiyaMessageNotification object:nil];
    
    // init license
    [AYLicenseManager initLicense:@"067ea67564164944b93e5e8825734781"];
    
    // init effect resource
    [self initResourceData];

    // GPUImage
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    _cameraPreview = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    _cameraPreview.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view addSubview:_cameraPreview];
    
    _effectFilter = [[AiyaEffectFilter alloc] init];
    
    [_videoCamera addTarget:_effectFilter];
    [_effectFilter addTarget:_cameraPreview];
    
    [_videoCamera startCameraCapture];
    
    // UI
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
#pragma mark ViewController lifecycle
- (void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    self.isViewAppear= YES;
    [_videoCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated{

    [_videoCamera stopCameraCapture];
    self.isViewAppear= NO;
    [super viewWillDisappear:animated];
}

- (void)enterBackground:(NSNotification *)notifi{

    if ([self isViewAppear]) {
        [_videoCamera stopCameraCapture];
    }
}

- (void)enterForeground:(NSNotification *)notifi{

    if ([self isViewAppear]) {
        [_videoCamera startCameraCapture];
    }
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

- (void)aiyaMessage:(NSNotification *)notifi{
    
//    NSString *message = notifi.userInfo[AiyaMessageNotificationUserInfoKey];
//    NSLog(@"message : %@",message);
}

-(void)dealloc{

    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark-
#pragma mark ViewDelegate

- (void)onChangeCameraPosition:(AVCaptureDevicePosition)captureDevicePosition{


}

-(void)onEffectClick:(NSString *)path{
    [_effectFilter setEffect:path];
    [_effectFilter setEffectCount:0]; //无限循环播放
}

- (void)onSmoothChange:(float)intensity{
    [_effectFilter setSmooth:intensity];
    NSLog(@"smooth %f",intensity);
}

- (void)onRuddyChange:(float)intensity{
    [_effectFilter setSaturation:intensity];
    NSLog(@"ruddy %f",intensity);
}

- (void)onWhiteChange:(float)intensity{
    [_effectFilter setWhiten:intensity];
    NSLog(@"white %f",intensity);
}

- (void)onBigEyesScaleChange:(float)scale{
    [_effectFilter setBigEye:scale];
    NSLog(@"BigEye scale %f",scale);
}

- (void)onSlimFaceScaleChange:(float)scale{
    [_effectFilter setSlimFace:scale];
    NSLog(@"SlimFace scale %f",scale);
}

- (void)onStyleClick:(UIImage *)image{
    [_effectFilter setStyle:image];
}

- (void)onStyleChange:(float)style{
    _effectFilter.intensityOfStyle = style;
    NSLog(@"style %f",style);
}

@end
