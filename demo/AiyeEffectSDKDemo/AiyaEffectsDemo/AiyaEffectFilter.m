//
//  AiyaEffectFilter.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/12/3.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "AiyaEffectFilter.h"
#import <AiyaEffectSDK/AiyaEffectSDK.h>

#if DEBUG
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "DeviceMonitor.h"
static const int ddLogLevel = DDLogLevelVerbose;// 定义日志级别
static const int recordStep = 10; //每10帧做一次记录
#endif

@interface AiyaEffectFilter ()

@property (nonatomic, strong) AYEffectHandler *effectHandler;

#if DEBUG
@property (nonatomic, assign) BOOL initDDLog;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) NSDate *recordDate;
#endif

@end

@implementation AiyaEffectFilter

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;{
    
    //------------->绘制特效图像<--------------//
    
    if (!_effectHandler) {
        _effectHandler = [[AYEffectHandler alloc] init];
    }
    
    [self.effectHandler processWithTexture:firstInputFramebuffer.texture width:[self sizeOfFBO].width height:[self sizeOfFBO].height];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    [filterProgram use];
    //------------->绘制特效图像<--------------//
    
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    
#if DEBUG
    if (!_initDDLog) {
        _initDDLog = YES;
        DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:fileLogger];
    }
    if (self.frameCount % recordStep == 0) {
        if (self.recordDate) {
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.recordDate];
            NSInteger fps = 1.f / (timeInterval / recordStep);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                DDLogInfo(@"memoryUseage:%03.2f cpuUsage:%03.0f fps:%02ld",usedMemory() / 1024.f/1024.f,cpuUsage(),(long)fps);
            });
        }
        
        self.recordDate = [NSDate date];
    }
    self.frameCount++;
#endif
}

- (void)setEffect:(NSString *)path{
    [_effectHandler setEffectPath:path];
#if DEBUG
    DDLogInfo(@"effect %@",path);
#endif

}

- (void)setEffectCount:(NSUInteger)effectCount{
    [_effectHandler setEffectPlayCount:effectCount];
}

- (void)pauseEffect{
    [_effectHandler pauseEffect];
}

- (void)resumeEffect{
    [_effectHandler resumeEffect];
}

- (void)setSmooth:(CGFloat)intensity{
    [_effectHandler setSmooth:intensity];
#if DEBUG
    DDLogInfo(@"Smooth %f",intensity);
#endif

}

- (void)setSaturation:(CGFloat)intensity{
    [_effectHandler setSaturation:intensity];
#if DEBUG
    DDLogInfo(@"Saturation %f",intensity);
#endif

}

- (void)setWhiten:(CGFloat)intensity{
    [_effectHandler setWhiten:intensity];
#if DEBUG
    DDLogInfo(@"Whiten %f",intensity);
#endif

}

- (void)setBigEye:(CGFloat)intentsity{
    [_effectHandler setBigEye:intentsity];
#if DEBUG
    DDLogInfo(@"BigEye %f",intentsity);
#endif

}

- (void)setSlimFace:(CGFloat)intentsity{
    [_effectHandler setSlimFace:intentsity];
#if DEBUG
    DDLogInfo(@"SlimFace %f",intentsity);
#endif

}

- (void)setStyle:(UIImage *)style{
    [_effectHandler setStyle:style];
}

- (void)setIntensityOfStyle:(CGFloat)intensity{
    [_effectHandler setIntensityOfStyle:intensity];
}

@end
