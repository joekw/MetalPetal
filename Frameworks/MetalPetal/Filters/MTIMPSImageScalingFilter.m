//
//  MTIMPSGaussianBlurFilter.m
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import "MTIMPSImageScalingFilter.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"
#import "MTILock.h"

@interface MTIMPSImageScalingFilter ()

@end

@implementation MTIMPSImageScalingFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

+ (MTIMPSKernel *)kernelWithRadius:(NSInteger)radius {
    static NSMutableDictionary *kernels;
    static id<NSLocking> kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = MTILockCreate();
    });
    
    [kernelsLock lock];
    MTIMPSKernel *kernel = kernels[@(radius)];
    if (!kernel) {
        //ceil(sqrt(-log(0.01)*2)*sigma) ~ ceil(3.7*sigma)
        float sigma = radius;
        kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            MPSImageGaussianBlur *k = [[MPSImageGaussianBlur alloc] initWithDevice:device sigma:sigma];
            k.edgeMode = MPSImageEdgeModeClamp;
            return k;
        }];
        kernels[@(radius)] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (ceil(self.radius) <= 0) {
        return self.inputImage;
    }
    return [[self.class kernelWithRadius:ceil(self.radius)] applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) outputPixelFormat:_outputPixelFormat];
}

@end
