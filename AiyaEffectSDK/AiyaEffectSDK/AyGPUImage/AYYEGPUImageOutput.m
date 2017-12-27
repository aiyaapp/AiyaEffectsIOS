#import "AYYEGPUImageOutput.h"

@implementation AYYEGPUImageOutput

@synthesize frameProcessingCompletionBlock = _frameProcessingCompletionBlock;
@synthesize outputTextureOptions = _outputTextureOptions;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(AYYEGPUImageContext *)context;
{
	if (!(self = [super init]))
    {
		return nil;
    }

    targets = [[NSMutableArray alloc] init];
    targetTextureIndices = [[NSMutableArray alloc] init];
    
    // set default texture options
    _outputTextureOptions.minFilter = GL_LINEAR;
    _outputTextureOptions.magFilter = GL_LINEAR;
    _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.internalFormat = GL_RGBA;
    _outputTextureOptions.format = GL_BGRA;
    _outputTextureOptions.type = GL_UNSIGNED_BYTE;
    
    self.context = context;

    return self;
}

- (void)dealloc 
{
    [self removeAllTargets];
}

#pragma mark -
#pragma mark Managing targets

- (void)setInputFramebufferForTarget:(id<AYYEGPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:inputTextureIndex];
}

- (AYYEGPUImageFramebuffer *)framebufferForOutput;
{
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer;
{
    outputFramebuffer = nil;
}

- (NSArray*)targets;
{
	return [NSArray arrayWithArray:targets];
}

- (void)addTarget:(id<AYYEGPUImageInput>)newTarget;
{
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
}

- (void)addTarget:(id<AYYEGPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    runAYYESynchronouslyOnContextQueue(self.context, ^{
        [self setInputFramebufferForTarget:newTarget atIndex:textureLocation];
        [targets addObject:newTarget];
        [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
    });
}

- (void)removeTarget:(id<AYYEGPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];

    runAYYESynchronouslyOnContextQueue(self.context, ^{
        [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
		[targetToRemove setInputRotation:kAYYEGPUImageNoRotation atIndex:textureIndexOfTarget];

        [targetTextureIndices removeObjectAtIndex:indexOfObject];
        [targets removeObject:targetToRemove];
        [targetToRemove endProcessing];
    });
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    runAYYESynchronouslyOnContextQueue(self.context, ^{
        for (id<AYYEGPUImageInput> targetToRemove in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
            [targetToRemove setInputRotation:kAYYEGPUImageNoRotation atIndex:textureIndexOfTarget];
        }
        [targets removeAllObjects];
        [targetTextureIndices removeAllObjects];
    });
}

#pragma mark -
#pragma mark Accessors

-(void)setOutputTextureOptions:(AYYEGPUTextureOptions)outputTextureOptions
{
    _outputTextureOptions = outputTextureOptions;
    
    if( outputFramebuffer.texture )
    {
        glBindTexture(GL_TEXTURE_2D,  outputFramebuffer.texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _outputTextureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _outputTextureOptions.wrapT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

@end
