//
//  TestVideoViewController.m
//  Memento
//
//  Created by Ömer Faruk Gül on 22/05/15.
//  Copyright (c) 2015 Ömer Faruk Gül. All rights reserved.
//

#import "VideoViewController.h"
@import AVFoundation;
#import "MP4ReEncode.h"
#import "VideoEffectHandlerView.h"

@interface VideoViewController () <MP4ReEncodeDelegate>{
    
    CGSize outputSize;
    GLfloat preferredTransformMatrix[16];

}

@property (strong, nonatomic) AVPlayer *avPlayer;
@property (strong, nonatomic) AVPlayerLayer *avPlayerLayer;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) MP4ReEncode *reencode;
@property (strong, nonatomic) VideoEffectHandlerView *videoEffectHandlerView;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator ;

@property (nonatomic, assign) NSInteger frameIndex;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _videoEffectHandlerView = [[VideoEffectHandlerView alloc]initWithFrame:self.view.bounds];    
    [self.view addSubview:_videoEffectHandlerView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhiteLarge)];
    [self.activityIndicator setFrame:self.view.bounds];
    [self.view addSubview:self.activityIndicator];
    
    [self startReEncode];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)startReEncode{
    if (!self.reencode) {
        self.reencode = [[MP4ReEncode alloc] init];
        self.reencode.delegate = self;
    }
    [self.reencode initSetup];
    
    self.reencode.inputURL = _url;
    
    NSString *savePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingPathExtension:@"mp4"]];
    self.reencode.outputURL = [NSURL fileURLWithPath:savePath];
    
    // 打开菊花
    [self.activityIndicator startAnimating];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.reencode startReencode];
    });
}

#pragma mark - MP4ReEncodeDelegate

- (void)MP4ReEncodeVideoParamWithNaturalSize:(CGSize *)naturalSize preferredTransform:(CGAffineTransform *)preferredTransform{
    //  旋转视频图像为正方向
    outputSize = CGSizeApplyAffineTransform(*naturalSize, *preferredTransform);
    
    if (outputSize.width < 0) {
        outputSize.width *= -1;
    }
    if (outputSize.height < 0) {
        outputSize.height *= -1;
    }
    
    // 三维空间旋转
    // https://zh.wikipedia.org/wiki/%E6%97%8B%E8%BD%AC%E7%9F%A9%E9%98%B5
        
    // 计算视频旋转角度
    CGFloat videoRadians = atan2(preferredTransform->b, preferredTransform->a);
    
    preferredTransformMatrix[0] = cosf(videoRadians);//preferredTransform->a;
    preferredTransformMatrix[1] = -sinf(videoRadians);//preferredTransform->c;
    preferredTransformMatrix[2] = 0.0f;
    preferredTransformMatrix[3] = 0.0f;
    
    preferredTransformMatrix[4] = sinf(videoRadians);//preferredTransform->b;
    preferredTransformMatrix[5] = cosf(videoRadians);//preferredTransform->d;
    preferredTransformMatrix[6] = 0.0f;
    preferredTransformMatrix[7] = 0.0f;
    
    preferredTransformMatrix[8] = 0.0f;
    preferredTransformMatrix[9] = 0.0f;
    preferredTransformMatrix[10] = 1.0f;
    preferredTransformMatrix[11] = 0.0f;
    
    preferredTransformMatrix[12] = 0.0f;
    preferredTransformMatrix[13] = 0.0f;
    preferredTransformMatrix[14] = 0.0f;
    preferredTransformMatrix[15] = 1.0f;
    
    *naturalSize = outputSize;
    *preferredTransform = CGAffineTransformIdentity;
}

- (CMSampleBufferRef)MP4ReEncodeProcessVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    __block CMSampleBufferRef tempSampleBuffer;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        if([self.effectRecordDic objectForKey:@(self.frameIndex)] != nil){
            [self.videoEffectHandlerView setEffectType:[[self.effectRecordDic objectForKey:@(self.frameIndex)] integerValue]];
        }
                
        tempSampleBuffer = [self.videoEffectHandlerView process:sampleBuffer transformMatrix:preferredTransformMatrix outputSize:outputSize];
        self.frameIndex++;
    });
    
    CMTime time = CMSampleBufferGetPresentationTimeStamp(tempSampleBuffer);
    NSLog(@"time : %"PRId64" / %"PRId32, time.value/10, time.timescale/10 );
    
    return tempSampleBuffer;
}

- (void) MP4ReEncodeFinish:(bool)success{
    [self.videoEffectHandlerView removeFromSuperview];
    
    // the video player
    self.avPlayer = [AVPlayer playerWithURL:self.reencode.outputURL];
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.avPlayer currentItem]];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    self.avPlayerLayer.frame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
    [self.view.layer addSublayer:self.avPlayerLayer];
    
    // cancel button
    [self.view addSubview:self.cancelButton];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.frame = CGRectMake(0, 10, 44, 44);
    
    [self.activityIndicator stopAnimating];
    
    [self.avPlayer play];
}

#pragma mark - loop play
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

#pragma mark - UI
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIButton *)cancelButton {
    if(!_cancelButton) {
        UIImage *cancelImage = [UIImage imageNamed:@"cancel.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tintColor = [UIColor whiteColor];
        [button setImage:cancelImage forState:UIControlStateNormal];
        button.imageView.clipsToBounds = NO;
        button.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        button.layer.shadowColor = [UIColor blackColor].CGColor;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowOpacity = 0.4f;
        button.layer.shadowRadius = 1.0f;
        button.clipsToBounds = NO;
        
        _cancelButton = button;
    }
    
    return _cancelButton;
}

- (void)cancelButtonPressed:(UIButton *)button {
    
    [self.avPlayer pause];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"dealloc VideoViewController");
}

@end
