//
//  HomeViewController.m
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 29/10/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#import "HomeViewController.h"
#import "EditViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface HomeViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    UIImagePickerController *imagePicker;

}
@end

@implementation HomeViewController

- (void)viewDidLoad{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    imagePicker.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
    imagePicker.allowsEditing = NO;
    
    imagePicker.delegate = self;
    
    UIButton *bt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    bt.frame = CGRectMake(self.view.bounds.size.width / 2 - 50, self.view.bounds.size.height / 2, 100, 50);
    [bt setTitle:@"选择视频" forState:UIControlStateNormal];
    bt.titleLabel.font = [UIFont systemFontOfSize:20];
    [bt addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt];
}

- (void)onClick:(UIButton *)bt{
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    NSURL *mediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    //获取封面图
    NSError *error;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(1, 1000);
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    EditViewController *editVC = [[EditViewController alloc]init];
    editVC.url = mediaURL;
    editVC.thumbnail = img;
    [self.navigationController pushViewController:editVC animated:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

@end
