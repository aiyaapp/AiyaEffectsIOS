#import <Foundation/Foundation.h>
#import "AYGPUImageOutput.h"

@interface AiyaGPUImageRawDataInput : AYGPUImageOutput


/**
 输入BGRA数据

 @param pixelBuffer BGRA格式的pixelBuffer
 */
- (void)processBGRADataWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;


/**
 输入YUV数据

 @param pixelBuffer YUV格式的pixelBuffer
 */
- (void)processYUVDataWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
