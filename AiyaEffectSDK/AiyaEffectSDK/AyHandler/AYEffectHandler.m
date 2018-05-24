//
//  AYEffectHandler.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYEffectHandler.h"
#import "AYGPUImageTextureInput.h"
#import "AYGPUImageTextureOutput.h"
#import "AYGPUImageRawDataInput.h"
#import "AYGPUImageRawDataOutput.h"

#if AY_ENABLE_TRACK
#import "AYGPUImageTrackOutput.h"
#endif

#if AY_ENABLE_EFFECT
#import "AYGPUImageEffectFilter.h"
#endif

#import "AYGPUImageLookupFilter.h"

#if AY_ENABLE_BEAUTY
#import "AYGPUImageBeautyFilter.h"
#import "AYGPUImageBigEyeFilter.h"
#import "AYGPUImageSlimFaceFilter.h"
#endif

@interface AYEffectHandler ()

@property (nonatomic, strong) AYGPUImageContext *glContext;
@property (nonatomic, strong) AYGPUImageTextureInput *textureInput;
@property (nonatomic, strong) AYGPUImageTextureOutput *textureOutput;
@property (nonatomic, strong) AYGPUImageRawDataInput *rawDataInput;
@property (nonatomic, strong) AYGPUImageRawDataOutput *rawDataOutput;

#if AY_ENABLE_TRACK
@property (nonatomic, strong) AYGPUImageTrackOutput *trackOutput;
@property (nonatomic, assign) void *faceData;
#endif

#if AY_ENABLE_EFFECT
@property (nonatomic, strong) AYGPUImageEffectFilter *effectFilter;
#endif

@property (nonatomic, strong) AYGPUImageLookupFilter *lookupFilter;

#if AY_ENABLE_BEAUTY
@property (nonatomic, strong) AYGPUImageBeautyFilter *beautyFilter;
@property (nonatomic, strong) AYGPUImageBigEyeFilter *bigEyeFilter;
@property (nonatomic, strong) AYGPUImageSlimFaceFilter *slimFaceFilter;
#endif

@property (nonatomic, assign) BOOL initRawDataProcess;
@property (nonatomic, assign) BOOL initTextureProcess;

@end

@implementation AYEffectHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        _glContext = [[AYGPUImageContext alloc] init];
        
        _textureInput = [[AYGPUImageTextureInput alloc] initWithContext:_glContext];
        _textureOutput = [[AYGPUImageTextureOutput alloc] initWithContext:_glContext];
        _rawDataInput = [[AYGPUImageRawDataInput alloc] initWithContext:_glContext];
        _rawDataOutput = [[AYGPUImageRawDataOutput alloc] initWithContext:_glContext];
    
#if AY_ENABLE_TRACK
        _trackOutput = [[AYGPUImageTrackOutput alloc] initWithContext:_glContext];
#endif
        
#if AY_ENABLE_BEAUTY
        _beautyFilter = [[AYGPUImageBeautyFilter alloc] initWithContext:_glContext type:AY_BEAUTY_TYPE_5];
        _beautyFilter.intensity = 0;
        _beautyFilter.smooth = 0;
        _beautyFilter.saturation = 0;
        _beautyFilter.whiten = 0;
#endif
        
        _lookupFilter = [[AYGPUImageLookupFilter alloc] initWithContext:_glContext];
        
#if AY_ENABLE_BEAUTY
        _bigEyeFilter = [[AYGPUImageBigEyeFilter alloc] initWithContext:_glContext];
        _bigEyeFilter.intensity = 0;
        
        _slimFaceFilter = [[AYGPUImageSlimFaceFilter alloc] initWithContext:_glContext];
        _slimFaceFilter.intensity = 0;
#endif
        
#if AY_ENABLE_EFFECT
        _effectFilter = [[AYGPUImageEffectFilter alloc] initWithContext:_glContext];
#endif
    }
    return self;
}

#if AY_ENABLE_EFFECT
- (void)setEffectPath:(NSString *)effectPath{
    _effectPath = effectPath;
    
    [self.effectFilter setEffectPath:effectPath];
}

- (void)setEffectPlayCount:(NSUInteger)effectPlayCount{
    _effectPlayCount = effectPlayCount;
    
    [self.effectFilter setEffectPlayCount:effectPlayCount];
}
#endif

- (void)pauseEffect{
#if AY_ENABLE_EFFECT
    [self.effectFilter pause];
#endif
}

- (void)resumeEffect{
#if AY_ENABLE_EFFECT
    [self.effectFilter resume];
#endif
}

- (void)setStyle:(UIImage *)style{
    _style = style;
    
    [self.lookupFilter setLookup:style];
}

- (void)setIntensityOfStyle:(CGFloat)intensityOfStyle{
    _intensityOfStyle = intensityOfStyle;
    
    [self.lookupFilter setIntensity:intensityOfStyle];
}

#if AY_ENABLE_BEAUTY
-(NSInteger)beautyAlgorithmType{
    return self.beautyFilter.type;
}

- (void)setSmooth:(CGFloat)smooth{
    _smooth = smooth;
    
    [self.beautyFilter setSmooth:smooth];
}

- (void)setSaturation:(CGFloat)saturation{
    _saturation = saturation;
    
    [self.beautyFilter setSaturation:saturation];
}

- (void)setWhiten:(CGFloat)whiten{
    _whiten = whiten;
    
    [self.beautyFilter setWhiten:whiten];
}

- (void)setBigEye:(CGFloat)bigEye{
    _bigEye = bigEye;
    
    [self.bigEyeFilter setIntensity:bigEye];
}

- (void)setSlimFace:(CGFloat)slimFace{
    _slimFace = slimFace;
    
    [self.slimFaceFilter setIntensity:slimFace];
}
#endif

- (void)setVerticalFlip:(BOOL)verticalFlip{
    _verticalFlip = verticalFlip;
    
    self.textureInput.verticalFlip = verticalFlip;
    self.textureOutput.verticalFlip = verticalFlip;
    self.rawDataInput.verticalFlip = verticalFlip;
    self.rawDataOutput.verticalFlip = verticalFlip;
}

- (void)processWithTexture:(GLuint)texture width:(GLint)width height:(GLint)height{
    
    // 获取当前绑定的FrameBuffer
    GLint bindingFrameBuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    GLint viewPoint[4];
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    NSMutableArray* vertexAttribEnableArray = [NSMutableArray arrayWithCapacity:10];
    NSInteger vertexAttribEnableArraySize = 10;
    for (int x = 0 ; x < vertexAttribEnableArraySize; x++) {
        GLint vertexAttribEnable;
        glGetVertexAttribiv(x, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &vertexAttribEnable);
        [vertexAttribEnableArray addObject:@(vertexAttribEnable)];
    }
    
    if (self.initRawDataProcess) {
        [self removeFilterTargers];
        
        self.initRawDataProcess = NO;
    }
    
    if (!self.initTextureProcess) {
        
        NSMutableArray *filterChainArray = [NSMutableArray array];
        
#if AY_ENABLE_BEAUTY
        [filterChainArray addObject:self.beautyFilter];
#endif
        
        [filterChainArray addObject:self.lookupFilter];
        
#if AY_ENABLE_BEAUTY
        [filterChainArray addObject:self.bigEyeFilter];
        [filterChainArray addObject:self.slimFaceFilter];
#endif
        
#if AY_ENABLE_EFFECT
        [filterChainArray addObject:self.effectFilter];
#endif
        
#if AY_ENABLE_TRACK
        [self.textureInput addTarget:self.trackOutput];
#endif
        if (filterChainArray.count > 0) {
            [self.textureInput addTarget:[filterChainArray firstObject]];
            
            for (int x = 0; x < filterChainArray.count - 1; x++) {
                [filterChainArray[x] addTarget:filterChainArray[x+1]];
            }
            
            [[filterChainArray lastObject] addTarget:self.textureOutput];
            
        }else {
            [self.textureInput addTarget:self.textureOutput];
        }
        
        self.initTextureProcess = YES;
    }

#if AY_ENABLE_TRACK
    _faceData = NULL;
    [self.trackOutput setFaceData:&_faceData];
    
#if AY_ENABLE_BEAUTY
    [self.bigEyeFilter setFaceData:&_faceData];
    [self.slimFaceFilter setFaceData:&_faceData];
#endif

#if AY_ENABLE_EFFECT
    [self.effectFilter setFaceData:&_faceData];
#endif
    
#endif
    
    // 设置输出的Filter
    [self.textureOutput setOutputTexture:texture width:width height:height];
    
    // 设置输入的Filter, 同时开始处理纹理数据
    [self.textureInput processBGRADataWithTexture:texture width:width height:height];

    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
    for (int x = 0 ; x < vertexAttribEnableArraySize; x++) {
        glEnableVertexAttribArray((int)vertexAttribEnableArray[x]);
    }
}

- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    // 获取当前绑定的FrameBuffer
    GLint bindingFrameBuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    GLint viewPoint[4];
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    if (self.initTextureProcess) {
        [self removeFilterTargers];
        
        self.initTextureProcess = NO;
    }
    
    if (!self.initRawDataProcess) {
        
        NSMutableArray *filterChainArray = [NSMutableArray array];
        
#if AY_ENABLE_BEAUTY
        [filterChainArray addObject:self.beautyFilter];
#endif
        
        [filterChainArray addObject:self.lookupFilter];
        
#if AY_ENABLE_BEAUTY
        [filterChainArray addObject:self.bigEyeFilter];
        [filterChainArray addObject:self.slimFaceFilter];
#endif
        
#if AY_ENABLE_EFFECT
        [filterChainArray addObject:self.effectFilter];
#endif
        
#if AY_ENABLE_TRACK
        [self.rawDataInput addTarget:self.trackOutput];
#endif
        if (filterChainArray.count > 0) {
            [self.rawDataInput addTarget:[filterChainArray firstObject]];
            
            for (int x = 0; x < filterChainArray.count - 1; x++) {
                [filterChainArray[x] addTarget:filterChainArray[x+1]];
            }
            
            [[filterChainArray lastObject] addTarget:self.rawDataOutput];
            
        }else {
            [self.rawDataInput addTarget:self.rawDataOutput];
        }
        
        self.initRawDataProcess = YES;
    }
    
#if AY_ENABLE_TRACK
    _faceData = NULL;
    [self.trackOutput setFaceData:&_faceData];
    
#if AY_ENABLE_BEAUTY
    [self.bigEyeFilter setFaceData:&_faceData];
    [self.slimFaceFilter setFaceData:&_faceData];
#endif
    
#if AY_ENABLE_EFFECT
    [self.effectFilter setFaceData:&_faceData];
#endif
    
#endif
    
    // 设置输出的Filter
    [self.rawDataOutput setOutputCVPixelBuffer:pixelBuffer];
    
    // 设置输入的Filter, 同时开始处理BGRA数据
    [self.rawDataInput processBGRADataWithCVPixelBuffer:pixelBuffer];

    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
}

- (void)removeFilterTargers{
    [self.textureInput removeAllTargets];
    [self.rawDataInput removeAllTargets];
    
#if AY_ENABLE_BEAUTY
    [self.beautyFilter removeAllTargets];
#endif
    
    [self.lookupFilter removeAllTargets];
    
#if AY_ENABLE_BEAUTY
    [self.bigEyeFilter removeAllTargets];
    [self.slimFaceFilter removeAllTargets];
#endif
    
#if AY_ENABLE_EFFECT
    [self.effectFilter removeAllTargets];
#endif
}

- (void)dealloc{
    [self removeFilterTargers];
}

@end
