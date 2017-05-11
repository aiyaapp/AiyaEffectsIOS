#import "AYGPUImageOutput.h"
#import "AYGPUImageFilter.h"

@interface AYGPUImageFilterGroup : AYGPUImageOutput <AYGPUImageInput>
{
    NSMutableArray *filters;
    BOOL isEndProcessing;
}

@property(readwrite, nonatomic, strong) AYGPUImageOutput<AYGPUImageInput> *terminalFilter;
@property(readwrite, nonatomic, strong) NSArray *initialFilters;
@property(readwrite, nonatomic, strong) AYGPUImageOutput<AYGPUImageInput> *inputFilterToIgnoreForUpdates; 

// Filter management
- (void)addFilter:(AYGPUImageOutput<AYGPUImageInput> *)newFilter;
- (AYGPUImageOutput<AYGPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
- (NSUInteger)filterCount;

@end
