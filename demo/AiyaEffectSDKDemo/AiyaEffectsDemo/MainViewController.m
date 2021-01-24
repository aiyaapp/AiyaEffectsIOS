//
//  MainViewController.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/20.
//  Copyright © 2021 深圳哎吖科技. All rights reserved.
//

#import "MainViewController.h"
#import "CameraViewController.h"
#import "AnimationViewController.h"
#import "RecordViewController.h"
#import <Masonry/Masonry.h>
#import "UIColor+Hex.h"
#import <AiyaEffectSDK/AiyaEffectSDK.h>

@interface MainViewController ()

@property (nonatomic, strong) NSMutableArray *effectData;
@property (nonatomic, strong) NSMutableArray *styleData;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *cameraBtn = [UIButton new];
    [cameraBtn setTitle:@"相机" forState:UIControlStateNormal];
    [cameraBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [cameraBtn setBackgroundColor:[UIColor colorWithHexString:@"#EEEEEE" alpha:1]];
    [cameraBtn.layer setMasksToBounds:YES];
    [cameraBtn.layer setCornerRadius:8];
    [cameraBtn addTarget:self action:@selector(onCameraBtnTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:cameraBtn];
    
    UIButton *animationBtn = [UIButton new];
    [animationBtn setTitle:@"动画" forState:UIControlStateNormal];
    [animationBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [animationBtn setBackgroundColor:[UIColor colorWithHexString:@"#EEEEEE" alpha:1]];
    [animationBtn.layer setMasksToBounds:YES];
    [animationBtn.layer setCornerRadius:8];
    [animationBtn addTarget:self action:@selector(onAnimationBtnTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:animationBtn];
    
    UIButton *recordBtn = [UIButton new];
    [recordBtn setTitle:@"录制" forState:UIControlStateNormal];
    [recordBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [recordBtn setBackgroundColor:[UIColor colorWithHexString:@"#EEEEEE" alpha:1]];
    [recordBtn.layer setMasksToBounds:YES];
    [recordBtn.layer setCornerRadius:8];
    [recordBtn addTarget:self action:@selector(onRecordBtnTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:recordBtn];
    
    [cameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(20);
        make.height.mas_equalTo(44);
    }];
    
    [animationBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.top.equalTo(cameraBtn.mas_bottom).offset(20);
        make.height.mas_equalTo(44);
    }];
    
    [recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.top.equalTo(animationBtn.mas_bottom).offset(20);
        make.height.mas_equalTo(44);
    }];
    
    // init license . apply license please open http://www.lansear.cn/product/bbtx or +8618676907096
    [AYLicenseManager initLicense:@"3a8dff7c222644b7abbde10b22ad779d" callback:^(int ret) {
        if (ret == 0) {
            NSLog(@"License 验证成功");
        } else {
            NSLog(@"License 验证失败");
        }
    }];
    
    [self initResourceData];
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


- (void)onCameraBtnTap:(UIButton *)bt{
    CameraViewController *vc = [CameraViewController new];
    vc.effectData = self.effectData;
    vc.styleData = self.styleData;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onAnimationBtnTap:(UIButton *)bt{
    AnimationViewController *vc = [AnimationViewController new];
    vc.effectData = self.effectData;
    vc.styleData = self.styleData;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onRecordBtnTap:(UIButton *)bt{
    RecordViewController *vc = [RecordViewController new];
    vc.effectData = self.effectData;
    vc.styleData = self.styleData;
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

@end
