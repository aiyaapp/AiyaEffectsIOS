#import "AYYEGPUImageFramebufferCache.h"

#import "AYYEGPUImageOutput.h"
#import "AYYEGPUImageFramebuffer.h"
#import "AYYEGPUImageContext.h"

@interface AYYEGPUImageFramebufferCache()
{
    NSMutableDictionary *framebufferCache;
}

@property (nonatomic, weak) AYYEGPUImageContext *context;

- (NSString *)hashForSize:(CGSize)size textureOptions:(AYYEGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

@end


@implementation AYYEGPUImageFramebufferCache

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(AYYEGPUImageContext *)context;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    self.context = context;

    framebufferCache = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Framebuffer management

- (NSString *)hashForSize:(CGSize)size textureOptions:(AYYEGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    if (missCVPixelBuffer)
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-CVBF", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
    else
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (AYYEGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(AYYEGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    __block AYYEGPUImageFramebuffer *framebufferFromCache = nil;
    runAYYESynchronouslyOnContextQueue(self.context, ^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        
        
        NSMutableArray *frameBufferArr = [framebufferCache objectForKey:lookupHash];

        if (frameBufferArr != nil && frameBufferArr.count > 0){
            framebufferFromCache = [frameBufferArr lastObject];
            [frameBufferArr removeLastObject];
            [framebufferCache setObject:frameBufferArr forKey:lookupHash];
        }
        
        if (framebufferFromCache == nil)
        {
            framebufferFromCache = [[AYYEGPUImageFramebuffer alloc] initWithContext:self.context size:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        }
    });

    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (AYYEGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    AYYEGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions missCVPixelBuffer:missCVPixelBuffer];
}

- (void)returnFramebufferToCache:(AYYEGPUImageFramebuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
    runAYYESynchronouslyOnContextQueue(self.context, ^{
        CGSize framebufferSize = framebuffer.size;
        AYYEGPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions missCVPixelBuffer:framebuffer.missCVPixelBuffer];
        
        NSMutableArray *frameBufferArr = [framebufferCache objectForKey:lookupHash];
        if (!frameBufferArr) {
            frameBufferArr = [NSMutableArray array];
        }
        
        [frameBufferArr addObject:framebuffer];
        [framebufferCache setObject:frameBufferArr forKey:lookupHash];
        
    });
}

@end
