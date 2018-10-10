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
#import "AYGPUImageBGRADataInput.h"
#import "AYGPUImageBGRADataOutput.h"
#import "AYGPUImageNV12DataInput.h"
#import "AYGPUImageNV12DataOutput.h"
#import "AYGPUImageI420DataInput.h"
#import "AYGPUImageI420DataOutput.h"

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

@interface AYEffectHandler () {
    GLint bindingFrameBuffer;
    GLint bindingRenderBuffer;
    GLint viewPoint[4];
    NSMutableArray<NSNumber *>* vertexAttribEnableArray;
    NSInteger vertexAttribEnableArraySize;
}

@property (nonatomic, strong) AYGPUImageContext *glContext;
@property (nonatomic, strong) AYGPUImageTextureInput *textureInput;
@property (nonatomic, strong) AYGPUImageTextureOutput *textureOutput;
@property (nonatomic, strong) AYGPUImageBGRADataInput *bgraDataInput;
@property (nonatomic, strong) AYGPUImageBGRADataOutput *bgraDataOutput;
@property (nonatomic, strong) AYGPUImageNV12DataInput *nv12DataInput;
@property (nonatomic, strong) AYGPUImageNV12DataOutput *nv12DataOutput;
@property (nonatomic, strong) AYGPUImageI420DataInput *i420DataInput;
@property (nonatomic, strong) AYGPUImageI420DataOutput *i420DataOutput;

@property (nonatomic, strong) AYGPUImageFilter *commonInputFilter;
@property (nonatomic, strong) AYGPUImageFilter *commonOutputFilter;

#if AY_ENABLE_TRACK
@property (nonatomic, strong) AYGPUImageTrackOutput *trackOutput;
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

@property (nonatomic, assign) BOOL initCommonProcess;
@property (nonatomic, assign) BOOL initProcess;

@end

@implementation AYEffectHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        vertexAttribEnableArraySize = 5;
        vertexAttribEnableArray = [NSMutableArray array];
        
        _glContext = [[AYGPUImageContext alloc] init];
        
        _textureInput = [[AYGPUImageTextureInput alloc] initWithContext:_glContext];
        _textureOutput = [[AYGPUImageTextureOutput alloc] initWithContext:_glContext];
        _bgraDataInput = [[AYGPUImageBGRADataInput alloc] initWithContext:_glContext];
        _bgraDataOutput = [[AYGPUImageBGRADataOutput alloc] initWithContext:_glContext];
        _nv12DataInput = [[AYGPUImageNV12DataInput alloc] initWithContext:_glContext];
        _nv12DataOutput = [[AYGPUImageNV12DataOutput alloc] initWithContext:_glContext];
        _i420DataInput = [[AYGPUImageI420DataInput alloc] initWithContext:_glContext];
        _i420DataOutput = [[AYGPUImageI420DataOutput alloc] initWithContext:_glContext];
        
        _commonInputFilter = [[AYGPUImageFilter alloc] initWithContext:_glContext];
        _commonOutputFilter = [[AYGPUImageFilter alloc] initWithContext:_glContext];
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
    
    if (effectPath == NULL || (![effectPath isEqualToString:@""] && ![[NSFileManager defaultManager] fileExistsAtPath:effectPath])) {
        NSLog(@"无效的特效资源路径");
        return;
    }
    
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
- (void)setBeautyAlgorithmType:(NSInteger)beautyAlgorithmType{
    _beautyAlgorithmType = beautyAlgorithmType;
    
    [self.beautyFilter setType:(AY_BEAUTY_TYPE)beautyAlgorithmType];
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

- (void)setRotateMode:(AYGPUImageRotationMode)rotateMode{
    _rotateMode = rotateMode;
    
    self.textureInput.rotateMode = rotateMode;
    self.bgraDataInput.rotateMode = rotateMode;
    self.nv12DataInput.rotateMode = rotateMode;
    self.i420DataInput.rotateMode = rotateMode;
    
    if (rotateMode == kAYGPUImageRotateLeft) {
        rotateMode = kAYGPUImageRotateRight;
    }else if (rotateMode == kAYGPUImageRotateRight) {
        rotateMode = kAYGPUImageRotateLeft;
    }
    
    self.textureOutput.rotateMode = rotateMode;
    self.bgraDataOutput.rotateMode = rotateMode;
    self.nv12DataOutput.rotateMode = rotateMode;
    self.i420DataOutput.rotateMode = rotateMode;
}

/**
 通用处理
 */
- (void)commonProcess {
    if (!self.initCommonProcess) {
        
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
        [self.commonInputFilter addTarget:self.trackOutput];
#endif
        if (filterChainArray.count > 0) {
            [self.commonInputFilter addTarget:[filterChainArray firstObject]];
            
            for (int x = 0; x < filterChainArray.count - 1; x++) {
                [filterChainArray[x] addTarget:filterChainArray[x+1]];
            }
            
            [[filterChainArray lastObject] addTarget:self.commonOutputFilter];
            
        }else {
            [self.textureInput addTarget:self.commonOutputFilter];
        }
        
        self.initCommonProcess = YES;
    }
    
#if AY_ENABLE_TRACK
    
#if AY_ENABLE_BEAUTY
    [self.bigEyeFilter setFaceData:self.trackOutput.faceData];
    [self.slimFaceFilter setFaceData:self.trackOutput.faceData];
#endif
    
#if AY_ENABLE_EFFECT
    [self.effectFilter setFaceData:self.trackOutput.faceData];
#endif
    
#endif
}

- (void)processWithTexture:(GLuint)texture width:(GLint)width height:(GLint)height{
    
    [self saveOpenGLState];
    
    [self commonProcess];
    
    if (!self.initProcess) {
        [self.textureInput addTarget:self.commonInputFilter];
        [self.commonOutputFilter addTarget:self.textureOutput];
        self.initProcess = YES;
    }
    
    // 设置输出的Filter
    [self.textureOutput setOutputWithBGRATexture:texture width:width height:height];
    
    // 设置输入的Filter, 同时开始处理纹理数据
    [self.textureInput processWithBGRATexture:texture width:width height:height];
    
    [self restoreOpenGLState];
}

- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer formatType:(OSType)formatType{
    
    [self saveOpenGLState];
    
    [self commonProcess];
    
    if (formatType == kCVPixelFormatType_32BGRA) {
        if (!self.initProcess) {
            [self.bgraDataInput addTarget:self.commonInputFilter];
            [self.commonOutputFilter addTarget:self.bgraDataOutput];
            self.initProcess = YES;
        }
        
        // 设置输出的Filter
        [self.bgraDataOutput setOutputWithBGRAPixelBuffer:pixelBuffer];
        
        // 设置输入的Filter, 同时开始处理BGRA数据
        [self.bgraDataInput processWithBGRAPixelBuffer:pixelBuffer];
        
    } else if (formatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        if (!self.initProcess) {
            [self.nv12DataInput addTarget:self.commonInputFilter];
            [self.commonOutputFilter addTarget:self.nv12DataOutput];
            self.initProcess = YES;
        }
        
        // 设置输出的Filter
        [self.nv12DataOutput setOutputWithPixelBuffer:pixelBuffer];
        
        // 设置输入的Filter, 同时开始处理YUV数据
        [self.nv12DataInput processWithPixelBuffer:pixelBuffer];
        
    }
    
    [self restoreOpenGLState];
}

- (void)processWithYBuffer:(void *)yBuffer uvBuffer:(void *)uvBuffer width:(int)width height:(int)height{
    
    [self saveOpenGLState];
    
    [self commonProcess];

    if (!self.initProcess) {
        [self.nv12DataInput addTarget:self.commonInputFilter];
        [self.commonOutputFilter addTarget:self.nv12DataOutput];
        self.initProcess = YES;
    }
    
    // 设置输出的Filter
    [self.nv12DataOutput setOutputWithYData:yBuffer uvData:uvBuffer width:width height:height];
    
    // 设置输入的Filter, 同时开始处理YUV数据
    [self.nv12DataInput processWithYData:yBuffer uvData:uvBuffer width:width height:height];
        
    [self restoreOpenGLState];
}

- (void)processWithYBuffer:(void *)yBuffer uBuffer:(void *)uBuffer vBuffer:(void *)vBuffer width:(int)width height:(int)height{
    
    [self saveOpenGLState];
    
    [self commonProcess];
    
    if (!self.initProcess) {
        [self.i420DataInput addTarget:self.commonInputFilter];
        [self.commonOutputFilter addTarget:self.i420DataOutput];
        self.initProcess = YES;
    }
    
    // 设置输出的Filter
    [self.i420DataOutput setOutputWithYData:yBuffer uData:uBuffer vData:vBuffer width:width height:height];
    
    // 设置输入的Filter, 同时开始处理YUV数据
    [self.i420DataInput processWithYData:yBuffer uData:uBuffer vData:vBuffer width:width height:height];
    
    [self restoreOpenGLState];
}

- (void)processWithBGRAData:(void *)bgraData width:(int)width height:(int)height{
    
    [self saveOpenGLState];
    
    [self commonProcess];
    
    if (!self.initProcess) {
        [self.bgraDataInput addTarget:self.commonInputFilter];
        [self.commonOutputFilter addTarget:self.bgraDataOutput];
        self.initProcess = YES;
    }
    
    // 设置输出的Filter
    [self.bgraDataOutput setOutputWithBGRAData:bgraData width:width height:height];
    
    // 设置输入的Filter, 同时开始处理YUV数据
    [self.bgraDataInput processWithBGRAData:bgraData width:width height:height];
    
    [self restoreOpenGLState];
}

/**
 保存opengl状态
 */
- (void)saveOpenGLState {
    // 获取当前绑定的FrameBuffer
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    // 获取当前绑定的RenderBuffer
    glGetIntegerv(GL_RENDERBUFFER_BINDING, (GLint *)&bindingRenderBuffer);
    
    // 获取viewpoint
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    // 获取顶点数据
    [vertexAttribEnableArray removeAllObjects];
    for (int x = 0 ; x < vertexAttribEnableArraySize; x++) {
        GLint vertexAttribEnable;
        glGetVertexAttribiv(x, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &vertexAttribEnable);
        if (vertexAttribEnable) {
            [vertexAttribEnableArray addObject:@(x)];
        }
    }
}

/**
 恢复opengl状态
 */
- (void)restoreOpenGLState {
    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    
    // 还原当前绑定的RenderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, bindingRenderBuffer);
    
    // 还原viewpoint
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
    
    // 还原顶点数据
    for (int x = 0 ; x < vertexAttribEnableArray.count; x++) {
        glEnableVertexAttribArray(vertexAttribEnableArray[x].intValue);
    }
}

- (void)removeFilterTargers{
    [self.textureInput removeAllTargets];
    [self.bgraDataInput removeAllTargets];
    [self.nv12DataInput removeAllTargets];
    
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
