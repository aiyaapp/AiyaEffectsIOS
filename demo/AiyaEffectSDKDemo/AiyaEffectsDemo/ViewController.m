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
    
    // init license . apply license please open http://www.lansear.cn/product/bbtx or +8618676907096
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
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"no_eff"],@"原始",@""]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"img2017"],@"2017",[effectRootDirPath stringByAppendingPathComponent:@"2017/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"baowener"],@"豹纹耳",[effectRootDirPath stringByAppendingPathComponent:@"baowener/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"gougou"],@"狗狗",[effectRootDirPath stringByAppendingPathComponent:@"gougou/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"fadai"],@"发带",[effectRootDirPath stringByAppendingPathComponent:@"fadai/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"grass"],@"小草",[effectRootDirPath stringByAppendingPathComponent:@"grass/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"huahuan"],@"花环",[effectRootDirPath stringByAppendingPathComponent:@"huahuan/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"majing"],@"马镜",[effectRootDirPath stringByAppendingPathComponent:@"majing/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"maoer"],@"猫耳",[effectRootDirPath stringByAppendingPathComponent:@"maoer/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"maorong"],@"毛绒",[effectRootDirPath stringByAppendingPathComponent:@"maorong/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"giraffe"],@"梅花鹿",[effectRootDirPath stringByAppendingPathComponent:@"giraffe/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"niu"],@"牛",[effectRootDirPath stringByAppendingPathComponent:@"niu/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"shoutao"],@"手套",[effectRootDirPath stringByAppendingPathComponent:@"shoutao/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"bunny"],@"兔耳",[effectRootDirPath stringByAppendingPathComponent:@"bunny/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"gaokongshiai"],@"高空示爱",[effectRootDirPath stringByAppendingPathComponent:@"gaokongshiai/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"shiwaitaoyuan"],@"世外桃源",[effectRootDirPath stringByAppendingPathComponent:@"shiwaitaoyuan/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"mojing"],@"魔镜",[effectRootDirPath stringByAppendingPathComponent:@"mojing/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"mogulin"],@"蘑菇林",[effectRootDirPath stringByAppendingPathComponent:@"mogulin/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"xiaohongmao"],@"小红帽",[effectRootDirPath stringByAppendingPathComponent:@"xiaohongmao/meta.json"]]];
    [self.effectData addObjectsFromArray:@[[UIImage imageNamed:@"arg"],@"国旗",[effectRootDirPath stringByAppendingPathComponent:@"arg/meta.json"]]];


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
