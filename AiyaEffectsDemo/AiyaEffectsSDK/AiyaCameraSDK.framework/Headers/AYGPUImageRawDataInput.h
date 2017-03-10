#import <Foundation/Foundation.h>
#import "AYGPUImageOutput.h"

@interface AYGPUImageRawDataInput : AYGPUImageOutput
{
    CGSize uploadedImageSize;
    
    dispatch_semaphore_t dataUpdateSemaphore;
}

// Initialization and teardown
- (id)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;

// Image rendering
- (void)updateDataFromBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
- (void)processData;
- (void)processDataForTimestamp:(CMTime)frameTime;
- (CGSize)outputImageSize;

@end
