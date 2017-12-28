//
//  EditView.h
//  AiyaVideoEffectSDKDemo
//
//  Created by 汪洋 on 2017/11/15.
//  Copyright © 2017年 Ömer Faruk Gül. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditViewDelegate <NSObject>

- (void)editViewOnSynthesized;

- (void)editViewOnCancel;

- (void)editViewOnTouchDown:(NSInteger)index;

- (void)editViewOnTouchUp;

@end

@interface EditView : UIView

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UIImage *thumbnail;

@property (nonatomic, weak) id<EditViewDelegate> delegate;

- (void)setProgress:(float)progress;

@end
