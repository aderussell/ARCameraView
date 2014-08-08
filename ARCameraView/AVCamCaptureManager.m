/*
     File: AVCamCaptureManager.m
 Abstract: Uses the AVCapture classes to capture video and still images.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "AVCamCaptureManager.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <ImageIO/CGImageProperties.h>

AVCaptureVideoOrientation AVCaptureVideoOrientationFromUIInterfaceOrientation(UIInterfaceOrientation orientation)
{
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            break;
    }
}


@interface AVCamUtilities : NSObject
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
@end

@implementation AVCamUtilities
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}
@end


@interface AVCamCaptureManager ()
@property AVCaptureDevicePosition currentDevicePosition;
@end

#pragma mark -
@interface AVCamCaptureManager (InternalUtilityMethods)
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *)frontFacingCamera;
- (AVCaptureDevice *)backFacingCamera;
@end


#pragma mark -
@implementation AVCamCaptureManager


- (void)dealloc
{
    [self teardownSession];
    //DLog(@"Capture Manager released");
}

- (BOOL)setupSession
{
    BOOL success = NO;
    
    if (self.session) {
        return success;
    }
    
    AVCaptureDevice *backFacingCamera = [self backFacingCamera];
    if (!backFacingCamera) {
        return NO;
    }
    
	// Set torch and flash mode to auto
	if ([backFacingCamera hasFlash]) {
		if ([backFacingCamera lockForConfiguration:nil]) {
			if ([backFacingCamera isFlashModeSupported:AVCaptureFlashModeAuto]) {
				[backFacingCamera setFlashMode:AVCaptureFlashModeAuto];
			}
			[backFacingCamera unlockForConfiguration];
		}
	}
	if ([backFacingCamera hasTorch]) {
		if ([backFacingCamera lockForConfiguration:nil]) {
			if ([backFacingCamera isTorchModeSupported:AVCaptureTorchModeAuto]) {
				[backFacingCamera setTorchMode:AVCaptureTorchModeAuto];
			}
			[backFacingCamera unlockForConfiguration];
		}
	}
	
    // Init the device inputs
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:nil];
    if (!newVideoInput) {
        return NO;
    }
    
	
    // Setup the still image file output
    AVCaptureStillImageOutput *newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [newStillImageOutput setOutputSettings:@{ AVVideoCodecKey : AVVideoCodecJPEG }];
    
    
    // Create session and set to produce high-quality photos
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    newCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    // Add inputs and output to the capture session
    if ([newCaptureSession canAddInput:newVideoInput]) {
        [newCaptureSession addInput:newVideoInput];
    }
    
    if ([newCaptureSession canAddOutput:newStillImageOutput]) {
        [newCaptureSession addOutput:newStillImageOutput];
    }
    
    self.stillImageOutput = newStillImageOutput;
    self.videoInput       = newVideoInput;
    self.session          = newCaptureSession;
	
    success = YES;
    
    return success;
}

- (void)stopSession
{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
}

- (BOOL)hasSession
{
    return (self.session != nil);
}

- (void)teardownSession
{
    if (self.session) {
        [self stopSession];
    
        [self.session removeInput:self.videoInput];
        [self.session removeOutput:self.stillImageOutput];
    
        self.stillImageOutput = nil;
        self.videoInput = nil;
        self.session = nil;
    }
}


- (BOOL)toggleCamera
{
    // TODO: add the cnage from front to back camera
    return NO;
}



- (void)captureStillImage
{
    
    
    AVCaptureConnection *stillImageConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.stillImageOutput connections]];
    if ([stillImageConnection isVideoOrientationSupported])
        [stillImageConnection setVideoOrientation:AVCaptureVideoOrientationFromUIInterfaceOrientation([[UIApplication sharedApplication] statusBarOrientation])];
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                             UIImage *image = nil;
                                                             if (imageDataSampleBuffer != NULL) {
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                 
                                                                 image = [[UIImage alloc] initWithData:imageData];
                                                                 //image = [UIImage imageWithCGImage:[image CGImage]
                                                                   //                  scale:[image scale]
                                                                     //          orientation: UIImageOrientationUp];
                                                             }
                                                             
                                                             // call the delegate method
                                                             if ([[self delegate] respondsToSelector:@selector(captureManagerStillImageCaptured:image:)]) {
                                                                 [[self delegate] captureManagerStillImageCaptured:self image:image];
                                                             }
                                                         }];
}


#pragma mark Device Counts
- (NSUInteger)cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}



#pragma mark Camera Properties
// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void)autoFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }        
    }
}

// Switch to continuous auto focus mode at the specified point
- (void)continuousFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
	
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
    {
		NSError *error;
		if ([device lockForConfiguration:&error])
        {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			[device unlockForConfiguration];
		} else {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)])
            {
                [[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}

@end

//----------------------------------------------------------------------------------//
#pragma mark - Internal Utility Methods

@implementation AVCamCaptureManager (InternalUtilityMethods)

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

// Find a front facing camera, returning nil if one is not found
- (AVCaptureDevice *)frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// Find a back facing camera, returning nil if one is not found
- (AVCaptureDevice *)backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

@end

