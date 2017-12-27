//
//  AyTrack.m
//  AyTrack
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AyTrack.h"
#import "FaceTrack.h"
#include "AYEffectConstants.h"
#include "FaceData.h"

static BOOL stopTrack = NO;

@interface AyTrack () {
    std::shared_ptr<AiyaTrack::FaceTrack> faceTrack;
    
    FaceData faceData;
}

@end

@implementation AyTrack

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"AiyaEffectSDK.bundle"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            stopTrack = YES;
        }
        
        std::string str(path.UTF8String);
        
        faceTrack = std::make_shared<AiyaTrack::FaceTrack>(str);
    }
    return self;
}

- (void)trackWithPixelBuffer:(unsigned char*)pixelBuffer bufferWidth:(int)width bufferHeight:(int)height trackData:(void **)trackData{
    
    if (stopTrack) {
        NSLog(@"请导入 AiyaEffectSDK.bundle ");
        return ;
    }
    
    int result = faceTrack->track(pixelBuffer, width, height, AiyaTrack::tImageTypeRGBA, &faceData);
    
    if (result == 0){
        *trackData = &faceData;
    }
}


@end
