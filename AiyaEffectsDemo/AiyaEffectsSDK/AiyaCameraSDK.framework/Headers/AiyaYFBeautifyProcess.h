//
//  AiyaYFBeautifyProcess.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/23.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AiyaCameraSDK/AiyaGPUImageYFBeautifyFilter.h>

@interface AiyaYFBeautifyProcess : NSObject

/**
 设置美颜等级
 */
@property (nonatomic, assign) AIYA_YF_BEAUTY_LEVEL beautyLevel;

/**
 设置美颜类型 默认0
 */
@property (nonatomic, assign) AIYA_YF_BEAUTY_TYPE beautyType;

/**
 使用设置的美颜等级,对图像数据进行美颜处理

 @param pixelBuffer 图像数据
 */
- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
