#import <UIKit/UIKit.h>
#import "AYGPUImageContext.h"

typedef NS_ENUM(NSUInteger, AYGPUImageFillModeType) {
    kAYGPUImageFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kAYGPUImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kAYGPUImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
};



/**
 UIView subclass to use as an endpoint for displaying AYGPUImage outputs
 */
@interface AYGPUImageView : UIView <AYGPUImageInput>
{
    AYGPUImageRotationMode inputRotation;
}

/** The fill mode dictates how images are fit in the view, with the default being kAYGPUImageFillModePreserveAspectRatio
 */
@property(readwrite, nonatomic) AYGPUImageFillModeType fillMode;

/** This calculates the current display size, in pixels, taking into account Retina scaling factors
 */
@property(readonly, nonatomic) CGSize sizeInPixels;

@property(nonatomic) BOOL enabled;

/** Handling fill mode
 
 @param redComponent Red component for background color
 @param greenComponent Green component for background color
 @param blueComponent Blue component for background color
 @param alphaComponent Alpha component for background color
 */
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;

@end
