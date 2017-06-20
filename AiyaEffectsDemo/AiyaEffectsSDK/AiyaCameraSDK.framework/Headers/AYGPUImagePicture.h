#import <UIKit/UIKit.h>
#import "AYGPUImageOutput.h"


@interface AYGPUImagePicture : AYGPUImageOutput
{
    CGSize pixelSizeOfImage;
    BOOL hasProcessedImage;
    
    dispatch_semaphore_t imageUpdateSemaphore;
}

// Initialization and teardown
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(UIImage *)newImageSource;
- (id)initWithCGImage:(CGImageRef)newImageSource;
- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
- (id)initWithCGImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
- (id)initWithImage:(UIImage *)newImageSource removePremultiplication:(BOOL)removePremultiplication;
- (id)initWithCGImage:(CGImageRef)newImageSource removePremultiplication:(BOOL)removePremultiplication;
- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput removePremultiplication:(BOOL)removePremultiplication;
- (id)initWithCGImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput removePremultiplication:(BOOL)removePremultiplication;

// Image rendering
- (void)processImage;
- (CGSize)outputImageSize;

/**
 * Process image with all targets and filters asynchronously
 * The completion handler is called after processing finished in the
 * GPU's dispatch queue - and only if this method did not return NO.
 *
 * @returns NO if resource is blocked and processing is discarded, YES otherwise
 */
- (BOOL)processImageWithCompletionHandler:(void (^)(void))completion;
- (void)processImageUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage))block;

@end
