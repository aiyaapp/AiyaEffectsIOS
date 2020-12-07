//
//  CameraView.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import "CameraView.h"
#import "CircleCell.h"

#import <Masonry/Masonry.h>

@interface CameraView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *bottomLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *switchCamera;
@property (nonatomic, strong) UIButton *effectBt;
@property (nonatomic, strong) UIButton *beautifyBt;
@property (nonatomic, strong) UIButton *styleBt;
@property (nonatomic, strong) UISlider *slider;

//mode 0 show effectcell
//mode 1 show beautifycell
//mode 2 shwo stylecell
@property (nonatomic, assign) NSUInteger mode;

//sliderMode 0 show smooth
//sliderMode 1 show ruddy
//sliderMode 2 show white
//sliderMode 3 show bigEyes
//sliderMode 4 show slimFace
//sliderMode 5 show style
@property (nonatomic, assign) NSUInteger sliderMode;

// default hidden
@property (nonatomic, assign) BOOL isShowEffectCollectionView;
@property (nonatomic, assign) BOOL isShowBeautifyCollectionView;
@property (nonatomic, assign) BOOL isShowStyleCollectionView;

//data step 3 UIImage|Text
@property (nonatomic, strong) NSArray *beautifyData;
@end

@implementation CameraView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubview];
        
        _beautifyData = @[
                        [UIImage imageNamed:@"beautify"],@"磨皮",
                        [UIImage imageNamed:@"beautify"],@"红润",
                        [UIImage imageNamed:@"beautify"],@"美白",
                        [UIImage imageNamed:@"beautify"],@"大眼",
                        [UIImage imageNamed:@"beautify"],@"瘦脸",
                        [UIImage imageNamed:@"beautify"],@"模糊",
                        ];
    }
    return self;
}

- (void)setupSubview{
    UICollectionViewFlowLayout *flowFlayout = [[UICollectionViewFlowLayout alloc] init];
    flowFlayout.itemSize = CGSizeMake(55.0,71.0);
    flowFlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.bottomLayout = [[UIView alloc]init];
    self.bottomLayout.clipsToBounds = YES;

    _collectionView = [[UICollectionView alloc] initWithFrame: CGRectZero collectionViewLayout:flowFlayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass: [CircleCell class] forCellWithReuseIdentifier: @"CircleCell"];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    _effectBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.effectBt setImage:[UIImage imageNamed:@"bt_camera_texiao_nor"] forState:UIControlStateNormal];
    [_effectBt addTarget:self action:@selector(onEffectBtClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _beautifyBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.beautifyBt setImage:[UIImage imageNamed:@"bt_camera_beauty"] forState:UIControlStateNormal];
    [_beautifyBt addTarget:self action:@selector(onBeautifyBtClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _styleBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.styleBt setImage:[UIImage imageNamed:@"bt_camera_style_filter"] forState:UIControlStateNormal];
    [_styleBt addTarget:self action:@selector(onStyleBtClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _slider = [[UISlider alloc] init];
    self.slider.minimumValue = 0;//设置可变最小值
    self.slider.maximumValue = 6;//设置可变最大值
    self.slider.value = 0;
    self.slider.hidden = YES;
    [self.slider addTarget:self action:@selector(sliderValueChange) forControlEvents:UIControlEventValueChanged];
    
    _switchCamera = [[UIButton alloc] init];
    [self.switchCamera setTitle:@"切换相机" forState:UIControlStateNormal];
    self.switchCamera.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.switchCamera setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.switchCamera addTarget:self action:@selector(onSwitchCameraClick:) forControlEvents:UIControlEventTouchUpInside];

    [self.bottomLayout addSubview:self.collectionView];
    [self.bottomLayout addSubview:self.effectBt];
    [self.bottomLayout addSubview:self.beautifyBt];
    [self.bottomLayout addSubview:self.styleBt];
    [self addSubview:self.bottomLayout];
    [self addSubview:self.slider];
    [self addSubview:self.switchCamera];
    
    [self.bottomLayout mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.bottom.equalTo(self.mas_bottom);
        make.height.mas_equalTo(165);
    }];
    
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(150);
        make.centerX.equalTo(self.mas_centerX);
        make.bottom.equalTo(self.bottomLayout.mas_top).offset(-10);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomLayout.mas_left);
        make.right.equalTo(self.bottomLayout.mas_right);
        make.height.mas_equalTo(71);
        make.bottom.equalTo(self.bottomLayout).offset(-185);
    }];

    [self.effectBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.left.equalTo(self.bottomLayout.mas_left).offset(36);
        make.bottom.equalTo(self.bottomLayout.mas_bottom).offset(-65);
    }];
    
    [self.beautifyBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.right.equalTo(self.bottomLayout.mas_right).offset(-36);
        make.bottom.equalTo(self.bottomLayout.mas_bottom).offset(-65);
    }];
    
    [self.styleBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.right.equalTo(self.beautifyBt.mas_left).offset(-36);
        make.bottom.equalTo(self.bottomLayout.mas_bottom).offset(-65);
    }];
    
    [self.switchCamera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(100, 44));
        make.top.equalTo(self.mas_top).offset(50);
        make.centerX.equalTo(self.mas_centerX);
    }];
}

- (void)setEffectData:(NSArray *)effectData{
    
    _effectData = effectData;
    [self.collectionView reloadData];
}

- (void)setStyleData:(NSArray *)styleData{
    
    _styleData = styleData;
    [self.collectionView reloadData];
}

- (void)onEffectBtClick:(UIButton *)bt{
    
    if (self.isShowEffectCollectionView) {
        [self hidenCollectionView];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = NO;
        
    }else if (self.isShowBeautifyCollectionView || self.isShowStyleCollectionView){
        self.mode = 0;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = YES;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = NO;
        self.slider.hidden = YES;
        
    }else {
        [self showCollectionView];
        self.mode = 0;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = YES;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = NO;
    }
}

- (void)onBeautifyBtClick:(UIButton *)bt{
    
    if (self.isShowBeautifyCollectionView) {
        [self hidenCollectionView];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = NO;
        self.slider.hidden = YES;
        
    }else if (self.isShowEffectCollectionView || self.isShowStyleCollectionView){
        self.mode = 1;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = YES;
        self.isShowStyleCollectionView = NO;
        self.slider.hidden = YES;
        
    }else {
        [self showCollectionView];
        self.mode = 1;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = YES;
        self.isShowStyleCollectionView = NO;
    }
}

- (void)onStyleBtClick:(UIButton *)bt{
    
    if (self.isShowStyleCollectionView) {
        [self hidenCollectionView];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = NO;
        self.slider.hidden = YES;
        
    }else if (self.isShowEffectCollectionView || self.isShowBeautifyCollectionView){
        self.mode = 2;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = YES;
        self.slider.hidden = YES;
        
    }else {
        [self showCollectionView];
        self.mode = 2;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
        self.isShowStyleCollectionView = YES;
    }
}

- (void)onSwitchCameraClick:(UIButton *)bt {
    if (self.delegate) {
        [self.delegate onSwitchCamera];
    }
}

- (void)showCollectionView{
    [UIView animateWithDuration:0.3 animations:^{

        [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-85);
        }];
        
        [self.beautifyBt mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-25);
        }];
        
        [self.effectBt mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-25);
        }];
        
        [self.styleBt mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-25);
        }];
        
        [self.bottomLayout layoutIfNeeded];
    }];
}

- (void)hidenCollectionView{
    [UIView animateWithDuration:0.3 animations:^{

        [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-185);
        }];
        
        [self.beautifyBt mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-65);
        }];
        
        [self.effectBt mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-65);
        }];
        
        [self.styleBt mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-65);
        }];
        
        [self.bottomLayout layoutIfNeeded];
    }];
}

#pragma mark -dataSoure
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    if (self.mode == 0) {
        return self.effectData.count / 3;
    }else if (self.mode == 1){
        return self.beautifyData.count / 2;
    }else if (self.mode == 2){
        return self.styleData.count / 3;
    }else
        return 0;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CircleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CircleCell" forIndexPath:indexPath];
    
    if (self.mode == 0) {
        cell.image = [self.effectData objectAtIndex:indexPath.row * 3];
        cell.text = [self.effectData objectAtIndex:indexPath.row * 3 + 1];
    }else if (self.mode == 1){
        cell.image = [self.beautifyData objectAtIndex:indexPath.row * 2];
        cell.text = [self.beautifyData objectAtIndex:indexPath.row * 2 + 1];
    }else if (self.mode == 2){
        cell.image = [self.styleData objectAtIndex:indexPath.row * 3];
        cell.text = [self.styleData objectAtIndex:indexPath.row * 3 + 1];
    }
    return cell;
}

#pragma mark -deletage
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.mode == 0) {
        if (self.delegate) {
            [self.delegate onEffectClick:[self.effectData objectAtIndex:indexPath.row * 3 + 2]];
        }
    }else if (self.mode == 1){
        self.slider.hidden = NO;
        
        self.sliderMode = indexPath.row;
        self.slider.minimumValue = 0;//设置可变最小值
        self.slider.maximumValue = 1;//设置可变最大值
        self.slider.value = 0;
        
        [self sliderValueChange];
        
    }else if (self.mode == 2){
        self.slider.hidden = NO;
        
        self.sliderMode = 6;
        self.slider.minimumValue = 0;//设置可变最小值
        self.slider.maximumValue = 1;//设置可变最大值
        self.slider.value = 0;
        
        if (self.delegate) {
            [self.delegate onStyleClick:[self.styleData objectAtIndex:indexPath.row * 3 + 2]];
        }
        
        [self sliderValueChange];
    }
}

- (void)sliderValueChange{
    if (self.sliderMode == 0) {
        if (self.delegate) {
            [self.delegate onSmoothChange:self.slider.value];
        }
    }else if (self.sliderMode == 1){
        if (self.delegate) {
            [self.delegate onRuddyChange:self.slider.value];
        }
    }else if (self.sliderMode == 2){
        if (self.delegate) {
            [self.delegate onWhiteChange:self.slider.value];
        }
    }else if (self.sliderMode == 3){
        if (self.delegate) {
            [self.delegate onBigEyesScaleChange:self.slider.value];
        }
    }else if (self.sliderMode == 4){
        if (self.delegate) {
            [self.delegate onSlimFaceScaleChange:self.slider.value];
        }
    }else if (self.sliderMode == 5){
        if (self.delegate) {
            [self.delegate onGaussianBlurChange:self.slider.value];
        }
    }else if (self.sliderMode == 6){
        if (self.delegate) {
            [self.delegate onStyleChange:self.slider.value];
        }
    }

}

@end
