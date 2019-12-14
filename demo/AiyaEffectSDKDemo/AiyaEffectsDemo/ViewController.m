//
//  ViewController.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "ViewController.h"
#import "CameraView.h"
#import "AYPixelBufferPreview.h"
#import "AYCamera.h"
#import <AiyaEffectSDK/AiyaEffectSDK.h>

@interface ViewController () <CameraViewDelegate, AYCameraDelegate, AYEffectHandlerDelegate>{
    
}

@property (nonatomic, assign) BOOL viewAppear;
@property (nonatomic, assign) BOOL stopPreview;

@property (nonatomic, strong) NSMutableArray *effectData;
@property (nonatomic, strong) NSMutableArray *styleData;

@property (nonatomic, strong) AYCamera *camera;
@property (nonatomic, strong) AYPixelBufferPreview *preview;

@property (nonatomic, strong) CALayer *focusBoxLayer;
@property (nonatomic, strong) CAAnimation *focusBoxAnimation;

@property (nonatomic, strong) NSLock *openGLLock;

@property (nonatomic, strong) AYEffectHandler *effectHandler;

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
    
    _openGLLock = [[NSLock alloc] init];
    
    // 相机, 录制视频分辩率
    _camera = [[AYCamera alloc] initWithResolution:AVCaptureSessionPreset1920x1080];
    _camera.delegate = self;
    [_camera setFrameRate:30];
        
    // 页面各种控件UI
    CameraView *cameraView = [[CameraView alloc] initWithFrame:self.view.frame];
    cameraView.effectData = self.effectData;
    cameraView.styleData = self.styleData;
    cameraView.delegate = self;
    [self.view addSubview:cameraView];
    
    // 相机预览UI
    _preview = [[AYPixelBufferPreview alloc] initWithFrame:self.view.frame];
    _preview.previewContentMode = AYPreivewContentModeScaleAspectFill;
    [cameraView insertSubview:_preview atIndex:0];
        
    // 手势UI, 添加点按手势, 点按时聚焦
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    [tapGesture setNumberOfTapsRequired:1];
    [_preview addGestureRecognizer:tapGesture];
    [_preview setUserInteractionEnabled:true];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
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

// MARK : Tap Screen
- (void)tapScreen:(UITapGestureRecognizer *)tapGesture {
    CGPoint point = [tapGesture locationInView:self.preview];
    
    CGPoint pointOfInterest = CGPointMake(point.y / self.preview.bounds.size.height, 1.0 - point.x / self.preview.bounds.size.width);
    
    [self.camera focusAtPoint:pointOfInterest];
    [self showFocusBox:point];
}

- (void)showFocusBox:(CGPoint)point {
    if (self.focusBoxLayer == NULL) {
        CALayer *focusBoxLayer = [[CALayer alloc] init];
        focusBoxLayer.cornerRadius = 3.0;
        focusBoxLayer.bounds = CGRectMake(0.0, 0.0, 70.0, 70.0);
        focusBoxLayer.borderWidth = 1.0;
        focusBoxLayer.borderColor = UIColor.yellowColor.CGColor;
        focusBoxLayer.opacity = 0.0;
        [self.view.layer addSublayer:focusBoxLayer];
        self.focusBoxLayer = focusBoxLayer;
    }
    
    if (self.focusBoxAnimation == NULL) {
        CABasicAnimation *focusBoxAnimation = [[CABasicAnimation alloc] init];
        focusBoxAnimation.keyPath = @"opacity";
        focusBoxAnimation.duration = 1;
        focusBoxAnimation.autoreverses = false;
        focusBoxAnimation.repeatCount = 0.0;
        focusBoxAnimation.fromValue = @(1.0);
        focusBoxAnimation.toValue = @(0.0);
        self.focusBoxAnimation = focusBoxAnimation;
    }
    
    [self.focusBoxLayer removeAllAnimations];
    
    [CATransaction begin];
    [CATransaction setValue:@(YES) forKey:kCATransactionDisableActions];
    self.focusBoxLayer.position = point;
    [CATransaction commit];
    
    [self.focusBoxLayer addAnimation:self.focusBoxAnimation forKey:@"animateOpacity"];
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
#pragma mark AYEffectHandlerDelegate

- (void)playEnd {
    NSLog(@"特效播放完成");
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
    
    [self.openGLLock unlock];
    
    //========== 当前为相机视频数据传输 线程==========//
}

- (void)cameraAudioOutput:(CMSampleBufferRef)sampleBuffer {
    //========== 当前为相机音频数据传输 线程==========//
    
    //========== 当前为相机音频数据传输 线程==========//
}


#pragma mark-
#pragma mark ViewDelegate

- (void)onSwitchCamera {
    if ([self.camera cameraPosition] == AVCaptureDevicePositionBack) {
        [self.camera setCameraPosition:AVCaptureDevicePositionFront];
    } else {
        [self.camera setCameraPosition:AVCaptureDevicePositionBack];
    }
}

-(void)onEffectClick:(NSString *)path{
    [self.effectHandler setEffectPath:path];
    [self.effectHandler setEffectPlayCount:0];  //无限循环播放
    NSLog(@"effectPath %@",path);
}

- (void)onSmoothChange:(float)intensity{
    [self.effectHandler setSmooth:intensity];
    NSLog(@"smooth %f",intensity);
}

- (void)onRuddyChange:(float)intensity{
    [self.effectHandler setSaturation:intensity];
    NSLog(@"ruddy %f",intensity);
}

- (void)onWhiteChange:(float)intensity{
    [self.effectHandler setWhiten:intensity];
    NSLog(@"white %f",intensity);
}

- (void)onBigEyesScaleChange:(float)scale{
    [self.effectHandler setBigEye:scale];
    NSLog(@"BigEye scale %f",scale);
}

- (void)onSlimFaceScaleChange:(float)scale{
    [self.effectHandler setSlimFace:scale];
    NSLog(@"SlimFace scale %f",scale);
}

- (void)onStyleClick:(UIImage *)image{
    [self.effectHandler setStyle:image];
}

- (void)onStyleChange:(float)style{
    self.effectHandler.intensityOfStyle = style;
    NSLog(@"style %f",style);
}

@end
