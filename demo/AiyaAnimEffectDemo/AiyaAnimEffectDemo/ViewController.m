//
//  ViewController.m
//  AiyaAnimEffectDemo
//
//  Created by 汪洋 on 2017/12/27.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <AiyaEffectSDKLite/AiyaEffectSDKLite.h>

@interface ViewController () <GLKViewDelegate>{
    GLKView *glkView;
    CADisplayLink* displayLink;
}

@property (nonatomic, strong) AYAnimHandler *animHandler;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // license state notification
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(licenseMessage:) name:AiyaLicenseNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aiyaMessage:) name:AiyaMessageNotification object:nil];
    
    // init license . apply license please open http://www.lansear.cn/product/bbtx or +8618676907096
    [AYLicenseManager initLicense:@"3a8dff7c222644b7abbde10b22ad779d"];
    
    // add blue view
    UIView *v = [[UIView alloc] initWithFrame:self.view.bounds];
    v.backgroundColor = [UIColor blueColor];
    [self.view addSubview:v];
    
    //使用GLKit创建opengl渲染环境
    glkView = [[GLKView alloc]initWithFrame:self.view.bounds context:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    glkView.backgroundColor = [UIColor clearColor];
    glkView.delegate = self;
    
    // add glkview
    [self.view addSubview:glkView];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    displayLink.frameInterval = 4;// 帧率 = 60 / frameInterval
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
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
    
    NSString *message = notifi.userInfo[AiyaMessageNotificationUserInfoKey];
    if ([@"AY_EFFECTS_REPLAY_END" isEqualToString:message]) {
        NSLog(@"多次播放完成");
        [displayLink invalidate];
    }
}

#pragma mark CADisplayLink selector
- (void)render:(CADisplayLink*)displayLink {
    [glkView display];
}

#pragma mark GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    if (!_animHandler) {
        //初始化AiyaAnimEffect
        _animHandler = [[AYAnimHandler alloc] init];
        self.animHandler.effectPath = [[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"mogulin"];
        self.animHandler.effectPlayCount = 2;
    }
    
    //清空画布
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.animHandler processWithWidth:(int)glkView.drawableWidth height:(int)glkView.drawableHeight];

}


@end
