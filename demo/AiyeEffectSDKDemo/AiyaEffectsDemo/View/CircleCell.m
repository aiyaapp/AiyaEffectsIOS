//
//  CircleCell.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import "CircleCell.h"

#import <Masonry/Masonry.h>

@interface CircleCell ()

@property (nonatomic, strong) UIImageView *imgView;

@property (nonatomic, strong) UILabel *label;

@end

@implementation CircleCell

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubview];
    }
    return self;
}

- (void)setupSubview{
    
    _imgView = [[UIImageView alloc]init];
    [self.imgView.layer setCornerRadius:27.5];
//    [self.imgView.layer setBorderWidth:1];
//    [self.imgView.layer setBorderColor:[UIColor colorWithRed:0xa9/255 green:0xac/255 blue:0x89/255 alpha:0.6f].CGColor];
    [self.imgView setClipsToBounds:YES];
    
    _label = [[UILabel alloc]init];
    [self.label setFont:[UIFont systemFontOfSize:14]];
    [self.label setTextColor:[UIColor whiteColor]];
    [self.label setTextAlignment:NSTextAlignmentCenter];
    
    [self.contentView addSubview:self.imgView];
    [self.contentView addSubview:self.label];
    
    [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top);
        make.width.equalTo(self.contentView.mas_width);
        make.height.equalTo(self.contentView.mas_width);
    }];
    
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imgView.mas_bottom);
        make.width.equalTo(self.contentView.mas_width);
        make.bottom.equalTo(self.contentView.mas_bottom);
    }];
}

- (void)setImage:(UIImage *)image{
    
    [self.imgView setImage:image];
}

- (void)setText:(NSString *)text{
    
    NSDictionary *fontAttributeDic = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                       NSStrokeColorAttributeName:[UIColor colorWithRed:0xa9/255 green:0xac/255 blue:0x89/255 alpha:0.6f],
                                       NSStrokeWidthAttributeName: @(-5)};
    NSMutableAttributedString *mutableAttributedStr = [[NSMutableAttributedString alloc]initWithString:text attributes:fontAttributeDic];
    [self.label setAttributedText:mutableAttributedStr];
}

@end
