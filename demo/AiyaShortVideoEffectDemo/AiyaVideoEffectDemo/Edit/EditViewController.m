//
//  EditViewController.m
//  AiyaVideoEffectSDKDemo
//
//  Created by 汪洋 on 2017/11/13.
//  Copyright © 2017年 Ömer Faruk Gül. All rights reserved.
//

#import "EditViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

//----------哎吖科技添加 开始----------
#import <AiyaEffectSDK/AiyaEffectSDK.h>
//----------哎吖科技添加 结束----------

#import "VideoViewController.h"
#import "EditView.h"

@interface EditViewController () <EditViewDelegate>

@property (nonatomic, strong) IJKFFMoviePlayerController *player;

//----------哎吖科技添加 开始----------
@property (nonatomic, strong) AYShortVideoEffectHandler *effectHandler;
//----------哎吖科技添加 结束----------

@property (nonatomic, assign) BOOL updateEffectType;
@property (nonatomic, assign) AY_SHORT_VIDEO_EFFECT_TYPE videoEffectType;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) EditView *editView;

@property (nonatomic, assign) NSInteger frameIndex;

@property (nonatomic, strong) NSMutableDictionary *effectRecordDic;

@end

@implementation EditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _effectRecordDic = [[NSMutableDictionary alloc] init];
    
//----------哎吖科技添加 开始----------
    // license state notification
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(licenseMessage:) name:AiyaLicenseNotification object:nil];
    [AYLicenseManager initLicense:@"108dd994a1874c20ba5b54453ea7d1f2"];
//----------哎吖科技添加 结束----------

    self.view.autoresizesSubviews = YES;
    self.editView = [[EditView alloc] initWithFrame:self.view.bounds];
    self.editView.thumbnail = self.thumbnail;
    self.editView.delegate = self;
    [self.view addSubview:self.editView];
    
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];

    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];

    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setOptionIntValue:1 forKey:@"mediacodec_auto_rotate" ofCategory:kIJKFFOptionCategoryPlayer];
    [options setOptionIntValue:1 forKey:@"mediacodec-handle-resolution-change" ofCategory:kIJKFFOptionCategoryPlayer];
    
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height - 100);
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = NO;
    [self.player prepareToPlay];

    __weak typeof(self) weakSelf = self;
    ((IJKFFMoviePlayerController *)self.player).renderBlock = ^(GLuint texture, GLint width,GLint height) {
        
        if (weakSelf.frameIndex == 0){// 从头开始
            [weakSelf.effectRecordDic removeAllObjects];
        }
        
//----------哎吖科技添加 开始----------
        // effectHandler 中的所有函数必须保证在同时一个线程中调用
        if (!weakSelf.effectHandler) {
            NSLog(@"init---------");
            weakSelf.effectHandler = [[AYShortVideoEffectHandler alloc] init];
        }

        if (weakSelf.updateEffectType) {
            NSLog(@"update----------");
            weakSelf.updateEffectType = NO;
            [weakSelf.effectHandler setType:weakSelf.videoEffectType];

            // 记录特效的点
            [weakSelf.effectRecordDic setObject:@(weakSelf.videoEffectType) forKey:@(weakSelf.frameIndex)];
        }

        [weakSelf.effectHandler processWithTexture:texture width:width height:height];
//----------哎吖科技添加 结束----------
        
        weakSelf.frameIndex ++;
    };
    
    [self.editView.playerView addSubview:self.player.view];
    
    // 监听播放时间
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil];
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

- (void)updateTime{
    if (self.player.isPlaying) {
        [self.editView setProgress:self.player.currentPlaybackTime / self.player.duration];
    }
}

- (void)playerDidFinish:(NSNotification *)notification{
    [self.editView setProgress:1];
    
    self.frameIndex = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.timer invalidate];
}

#pragma mark EditViewDelegate

- (void)editViewOnSynthesized{
    if (self.frameIndex != 0) {
        [self.effectRecordDic setObject:@(0) forKey:@(self.frameIndex)];
    }
    
    self.effectHandler = nil;
    
    VideoViewController *vc = [[VideoViewController alloc] init];
    vc.url = self.url;
    vc.effectRecordDic = self.effectRecordDic;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)editViewOnCancel{
    [self.timer invalidate];
    [self.player stop];
    [self.player shutdown];
    [self.player.view removeFromSuperview];
    self.player = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editViewOnTouchDown:(NSInteger)index{
        
    self.videoEffectType = index;
    self.updateEffectType = YES;
    
    [self.player play];
}

- (void)editViewOnTouchUp{
    
    [self.player pause];
}

- (void)dealloc{
    NSLog(@"dealloc EditViewController");
}
@end
