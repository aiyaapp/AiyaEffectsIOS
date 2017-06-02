//
//  AiyaGPUImageOutputFrameFilter.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/5/15.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "AYGPUImageFilter.h"
#import "AYGPUImageView.h"

@interface AiyaGPUImageOutputFrameFilter : NSObject<AYGPUImageInput>

/**
 输出的图像的大小
 */
@property (nonatomic, assign) CGSize outputFrameSize;

/**
 图像填充方式
 */
@property (nonatomic, assign) AYGPUImageFillModeType fillMode;

/**
 图像处理完成的回调block
 */
@property (nonatomic, copy) void(^frameProcessingCompletionBlock)(AYGPUImageFramebuffer*, CMTime);


@end
