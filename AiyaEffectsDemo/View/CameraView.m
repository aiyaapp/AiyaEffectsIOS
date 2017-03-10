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

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *effectBt;
@property (nonatomic, strong) UIButton *beautifyBt;

//mode 0 show effectcell; mode1 show beautifycell
@property (nonatomic, assign) NSUInteger mode;

// default hidden
@property (nonatomic, assign) BOOL isShowEffectCollectionView;
@property (nonatomic, assign) BOOL isShowBeautifyCollectionView;
@end

@implementation CameraView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubview];
    }
    return self;
}

- (void)setupSubview{
    UICollectionViewFlowLayout *flowFlayout = [[UICollectionViewFlowLayout alloc] init];
    flowFlayout.itemSize = CGSizeMake(55.0,71.0);
    flowFlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UIView *layout = [[UIView alloc]init];
    layout.clipsToBounds = YES;

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
    [self.beautifyBt setImage:[UIImage imageNamed:@"bt_camera_face_texiao_nor"] forState:UIControlStateNormal];
    [_beautifyBt addTarget:self action:@selector(onBeautifyBtClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [layout addSubview:self.collectionView];
    [layout addSubview:self.effectBt];
    [layout addSubview:self.beautifyBt];
    [self addSubview:layout];
    
    [layout mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.bottom.equalTo(self.mas_bottom);
        make.height.mas_equalTo(165);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(layout.mas_left);
        make.right.equalTo(layout.mas_right);
        make.height.mas_equalTo(71);
        make.bottom.equalTo(self.mas_bottom).offset(-185);
    }];

    [self.effectBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.left.equalTo(layout.mas_left).offset(36);
        make.bottom.equalTo(layout.mas_bottom).offset(-65);
    }];
    
    [self.beautifyBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.right.equalTo(layout.mas_right).offset(-36);
        make.bottom.equalTo(layout.mas_bottom).offset(-65);
    }];
}

- (void)setEffectData:(NSArray *)effectData{
    
    _effectData = effectData;
    [self.collectionView reloadData];
}

- (void)setBeautifyData:(NSArray *)beautifyData{
    
    _beautifyData = beautifyData;
    [self.collectionView reloadData];
}

- (void)onEffectBtClick:(UIButton *)bt{
    
    if (self.isShowEffectCollectionView) {
        [self hidenCollectionView];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
    }else if (self.isShowBeautifyCollectionView){
        self.mode = 0;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = YES;
        self.isShowBeautifyCollectionView = NO;
    }else {
        [self showCollectionView];
        self.mode = 0;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = YES;
        self.isShowBeautifyCollectionView = NO;
    }
}

- (void)onBeautifyBtClick:(UIButton *)bt{
    
    if (self.isShowBeautifyCollectionView) {
        [self hidenCollectionView];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = NO;
    }else if (self.isShowEffectCollectionView){
        self.mode = 1;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = YES;
    }else {
        [self showCollectionView];
        self.mode = 1;
        [self.collectionView reloadData];
        self.isShowEffectCollectionView = NO;
        self.isShowBeautifyCollectionView = YES;
    }
}

- (void)showCollectionView{
    [UIView animateWithDuration:0.3 animations:^{
        self.beautifyBt.center = CGPointMake(self.beautifyBt.center.x,self.beautifyBt.center.y + 39);
        self.effectBt.center = CGPointMake(self.effectBt.center.x,self.effectBt.center.y + 39);
        self.collectionView.center = CGPointMake(self.collectionView.center.x,self.collectionView.center.y + 100);
    }];
}

- (void)hidenCollectionView{
    [UIView animateWithDuration:0.3 animations:^{
        self.beautifyBt.center = CGPointMake(self.beautifyBt.center.x,self.beautifyBt.center.y - 39);
        self.effectBt.center = CGPointMake(self.effectBt.center.x,self.effectBt.center.y - 39);
        self.collectionView.center = CGPointMake(self.collectionView.center.x,self.collectionView.center.y - 100);
    }];
}

#pragma mark -dataSoure
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    if (self.mode == 0) {
        return self.effectData.count / 3;
    }else if (self.mode == 1){
        return self.beautifyData.count / 3;
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
        cell.image = [self.beautifyData objectAtIndex:indexPath.row * 3];
        cell.text = [self.beautifyData objectAtIndex:indexPath.row * 3 + 1];
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
        if (self.delegate) {
            [self.delegate onBeautyClick:[[self.beautifyData objectAtIndex:indexPath.row * 3 + 2]integerValue]];
        }
    }
}

@end
