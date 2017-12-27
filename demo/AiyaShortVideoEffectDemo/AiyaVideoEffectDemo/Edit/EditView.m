//
//  EditView.m
//  AiyaVideoEffectSDKDemo
//
//  Created by 汪洋 on 2017/11/15.
//  Copyright © 2017年 Ömer Faruk Gül. All rights reserved.
//

#import "EditView.h"

@interface EditView ()

@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UIProgressView *progreesView;

@property (nonatomic, strong) NSArray *effectArr;

@end

@implementation EditView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor blackColor]];
        
        _effectArr = @[@"灵魂出窍",@"抖动",@"黑魔法",@"虚拟镜像",@"萤火",@"时光隧道",@"躁动",@"终极变色",@"动感分屏",@"幻觉",
                               @"70s",@"炫酷转动",@"四分屏",@"三分屏",@"黑白闪烁"];
        
        _thumbnailView = [[UIImageView alloc] initWithImage:self.thumbnail];
        self.thumbnailView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 100);
        [self.thumbnailView setContentMode:UIViewContentModeScaleAspectFit];
        [self addSubview:self.thumbnailView];
        
        _playerView = [[UIView alloc] init];
        [self addSubview:self.playerView];
        
        // 进度条
        _progreesView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 102, self.bounds.size.width, 2)];
        self.progreesView.progressTintColor = [UIColor yellowColor];
        [self addSubview:self.progreesView];
        
        // 特效选择器
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 100, self.bounds.size.width, 100)];
        scrollView.contentSize = CGSizeMake(100 * self.effectArr.count, 100);
        scrollView.showsHorizontalScrollIndicator = YES;
        scrollView.backgroundColor = [UIColor blackColor];
        [self addSubview:scrollView];
        
        for (int x = 0; x < self.effectArr.count; x++) {
            // 加入特效编辑按钮
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setFrame:CGRectMake(x * 100 + 10, 10, 80, 80)];
            [button setTag:x];
            [button setImage:[UIImage imageNamed:self.effectArr[x]] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
            [button addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpOutside];
            [button addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchCancel];
            [scrollView addSubview:button];
        }
        
        //返回键
        UIImage *cancelImage = [UIImage imageNamed:@"cancel.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(0, 10, 44, 44);
        button.tintColor = [UIColor whiteColor];
        [button setImage:cancelImage forState:UIControlStateNormal];
        button.imageView.clipsToBounds = NO;
        button.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        button.layer.shadowColor = [UIColor blackColor].CGColor;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowOpacity = 0.4f;
        button.layer.shadowRadius = 1.0f;
        button.clipsToBounds = NO;
        [button addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        // 合成Mp4
        UIButton *synthesizedBt = [UIButton buttonWithType:UIButtonTypeCustom];
        synthesizedBt.frame = CGRectMake(self.bounds.size.width - 60, 10, 60, 44);
        [synthesizedBt setTitle:@"完成" forState:UIControlStateNormal];
        [synthesizedBt addTarget:self action:@selector(synthesized:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:synthesizedBt];
    }
    return self;
}


- (void)touchDown:(UIButton *)bt{
    if (self.delegate) {
        [self.delegate editViewOnTouchDown:bt.tag + 1];
    }
}

- (void)touchUp:(UIButton *)bt{
    if (self.delegate) {
        [self.delegate editViewOnTouchUp];
    }
}

- (void)setThumbnail:(UIImage *)thumbnail{
    [self.thumbnailView setImage:thumbnail];
}

- (void)setProgress:(float)progress{
    [self.progreesView setProgress:progress];
}

- (void)cancelButtonPressed:(UIButton *)button {
    if (self.delegate) {
        [self.delegate editViewOnCancel];
    }
}

- (void)synthesized:(UIButton *)button{
    if (self.delegate) {
        [self.delegate editViewOnSynthesized];
    }
}
@end
