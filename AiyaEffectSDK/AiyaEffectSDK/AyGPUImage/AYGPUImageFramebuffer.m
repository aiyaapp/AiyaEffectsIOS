//
//  AYGPUImageFramebuffer.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFramebuffer.h"

#import "AYGPUImageOutput.h"

@interface AYGPUImageFramebuffer()
{
    GLuint framebuffer;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    NSUInteger readLockCount;
}

- (void)generateFramebuffer;
- (void)generateTexture;
- (void)destroyFramebuffer;

@end

void dataAYProviderReleaseCallback (void *info, const void *data, size_t size);
void dataAYProviderUnlockCallback (void *info, const void *data, size_t size);

@implementation AYGPUImageFramebuffer

@synthesize size = _size;
@synthesize textureOptions = _textureOptions;
@synthesize texture = _texture;
@synthesize missCVPixelBuffer = _missCVPixelBuffer;
@synthesize framebufferReferenceCount = _framebufferReferenceCount;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(AYGPUImageContext *)context size:(CGSize)framebufferSize textureOptions:(AYGPUTextureOptions)fboTextureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _textureOptions = fboTextureOptions;
    _size = framebufferSize;
    _framebufferReferenceCount = 0;
    _missCVPixelBuffer = missCVPixelBuffer;
    self.context = context;
    
    [self generateFramebuffer];
    
    NSLog(@"Aiya 创建一个 OpenGL frameBuffer %d",framebuffer);
    
    return self;
}

- (void)dealloc
{
    NSLog(@"Aiya 销毁一个 OpenGL frameBuffer %d",framebuffer);
    
    [self destroyFramebuffer];
}

#pragma mark -
#pragma mark Internal

- (void)generateTexture;
{
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    // This is necessary for non-power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
    
    // TODO: Handle mipmaps
}

- (void)generateFramebuffer;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        // By default, all framebuffers on iOS 5.0+ devices are backed by texture caches, using one shared cache
        if (!_missCVPixelBuffer)
        {
            CVOpenGLESTextureCacheRef coreVideoTextureCache = [self.context coreVideoTextureCache];
            // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
            
            CFDictionaryRef empty; // empty value for attr value.
            CFMutableDictionaryRef attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
            if (err)
            {
                NSLog(@"FBO size: %f, %f", _size.width, _size.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                                NULL, // texture attributes
                                                                GL_TEXTURE_2D,
                                                                _textureOptions.internalFormat, // opengl format
                                                                (int)_size.width,
                                                                (int)_size.height,
                                                                _textureOptions.format, // native iOS format
                                                                _textureOptions.type,
                                                                0,
                                                                &renderTexture);
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);
            
            glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
            _texture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
        }
        else
        {
            [self generateTexture];
            
            glBindTexture(GL_TEXTURE_2D, _texture);
            
            glTexImage2D(GL_TEXTURE_2D, 0, _textureOptions.internalFormat, (int)_size.width, (int)_size.height, 0, _textureOptions.format, _textureOptions.type, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);
        }
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (framebuffer)
        {
            glDeleteFramebuffers(1, &framebuffer);
            framebuffer = 0;
        }
        
        if (/**[AYGPUImageContext supportsFastTextureUpload] &&*/ !_missCVPixelBuffer)
        {
            if (renderTarget)
            {
                CFRelease(renderTarget);
                renderTarget = NULL;
            }
            
            if (renderTexture)
            {
                CFRelease(renderTexture);
                renderTexture = NULL;
            }
        }
        else
        {
            glDeleteTextures(1, &_texture);
        }
        
    });
}

#pragma mark -
#pragma mark Usage

- (void)activateFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

#pragma mark -
#pragma mark Reference counting

- (void)lock;
{
    _framebufferReferenceCount++;
}

- (void)unlock;
{
    NSAssert(_framebufferReferenceCount > 0, @"Tried to overrelease a framebuffer, did you forget to call -useNextFrameForImageCapture before using -imageFromCurrentFramebuffer?");
    
    _framebufferReferenceCount--;
    if (_framebufferReferenceCount < 1)
    {
        
        [self.context.framebufferCache returnFramebufferToCache:self];
    }
    
}

- (void)clearAllLocks;
{
    _framebufferReferenceCount = 0;
}

#pragma mark -
#pragma mark Raw data bytes

- (void)lockForReading
{
//    if ([AYGPUImageContext supportsFastTextureUpload])
//    {
        if (readLockCount == 0)
        {
            CVPixelBufferLockBaseAddress(renderTarget, 0);
        }
        readLockCount++;
//    }
}

- (void)unlockAfterReading
{
//    if ([AYGPUImageContext supportsFastTextureUpload])
//    {
        NSAssert(readLockCount > 0, @"Unbalanced call to -[AYGPUImageFramebuffer unlockAfterReading]");
        readLockCount--;
        if (readLockCount == 0)
        {
            CVPixelBufferUnlockBaseAddress(renderTarget, 0);
        }
//    }
}

- (NSUInteger)bytesPerRow;
{
//    if ([AYGPUImageContext supportsFastTextureUpload])
//    {
        return CVPixelBufferGetBytesPerRow(renderTarget);
//    }
//    else
//    {
//        return _size.width * 4;
//    }
}

- (GLubyte *)byteBuffer;
{
    [self lockForReading];
    GLubyte * bufferBytes = CVPixelBufferGetBaseAddress(renderTarget);
    [self unlockAfterReading];
    return bufferBytes;
}

- (CVPixelBufferRef )pixelBuffer;
{
    return renderTarget;
}

- (GLuint)texture;
{
    return _texture;
}

- (UIImage *)image{
    
    CVPixelBufferLockBaseAddress(renderTarget, 0);
    
    //从 CVImageBufferRef 取得影像的细部信息
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(renderTarget);
    width = CVPixelBufferGetWidth(renderTarget);
    height = CVPixelBufferGetHeight(renderTarget);
    bytesPerRow = CVPixelBufferGetBytesPerRow(renderTarget);
    
    //利用取得影像细部信息格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    //透过 CGImageRef 将 CGContextRef 转换成 UIImage
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(renderTarget, 0);
    
    //成功转换成 UIImage
    return image;
}

@end
