#import "AYGPUImageVideoCamera.h"

void stillAYImageDataReleaseCallback(void *releaseRefCon, const void *baseAddress);
void AYGPUImageCreateResizedSampleBuffer(CVPixelBufferRef cameraFrame, CGSize finalSize, CMSampleBufferRef *sampleBuffer);

@interface AYGPUImageStillCamera : AYGPUImageVideoCamera

/** The JPEG compression quality to use when capturing a photo as a JPEG.
 */
@property CGFloat jpegCompressionQuality;

// Only reliably set inside the context of the completion handler of one of the capture methods
@property (readonly) NSDictionary *currentCaptureMetadata;

// Photography controls
- (void)capturePhotoAsSampleBufferWithCompletionHandler:(void (^)(CMSampleBufferRef imageSampleBuffer, NSError *error))block;
- (void)capturePhotoAsImageProcessedUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
- (void)capturePhotoAsImageProcessedUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withOrientation:(UIImageOrientation)orientation withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
- (void)capturePhotoAsJPEGProcessedUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(NSData *processedJPEG, NSError *error))block;
- (void)capturePhotoAsJPEGProcessedUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withOrientation:(UIImageOrientation)orientation withCompletionHandler:(void (^)(NSData *processedJPEG, NSError *error))block;
- (void)capturePhotoAsPNGProcessedUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(NSData *processedPNG, NSError *error))block;
- (void)capturePhotoAsPNGProcessedUpToFilter:(AYGPUImageOutput<AYGPUImageInput> *)finalFilterInChain withOrientation:(UIImageOrientation)orientation withCompletionHandler:(void (^)(NSData *processedPNG, NSError *error))block;

@end
