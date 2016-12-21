//
//  ARCameraView.m
//
//  Created by Adrian Russell on 06/08/2014.
//  Copyright (c) 2014 Adrian Russell. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import "ARCameraView.h"
#import "AVCamCaptureManager.h"
#import "UIImage+AspectResize.h"
#import "UIImage+FixOrientation.h"

#define CAMERA_BUTTON_DISTANCE_FROM_BOTTOM 40.0

//-----------------------------------------------------------------------------//
#pragma mark - Private Interface

@interface ARCameraView () <AVCamCaptureManagerDelegate>

/** The manager that handles the camera and the capture session. */
@property AVCamCaptureManager *captureManager;

/** The layer to which the live preview of the camera is displayed on the view. */
@property AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

/** The image view upon which the captured image is displayed. */
@property CALayer *imageView;

/** Whether, or not, The focus property of the camera is being observed. */
@property BOOL addedFocusKVO;

// redefined to add private write support
@property () UIImage *imageTaken;
@property () UIImage *wholeImageTaken;

@end

//-----------------------------------------------------------------------------//
#pragma mark - Main Implementation

@implementation ARCameraView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setup];
}


- (void)dealloc
{
    // if observing the focus status of the video device then remove observer.
    self.hideCaptureButtonDuringCameraAdjustingFocus = NO;
    
    // if the session is running then stop it and stop receiving orientation notifications.
    if ([[self.captureManager session] isRunning]) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
        [self.captureManager stopSession];
    }
    
    // destroy the capture session.
    [self.captureManager teardownSession];
}

/** Set up the basic properties of the camera view. This is called once when the view is inilialised. */
- (void)setup
{
    // setup view properties and defaults.
    self.backgroundColor = [UIColor blackColor];
    self.layer.masksToBounds = YES;
    self.hideCaptureButtonDuringCameraAdjustingFocus = YES;
    
    // create the capture manager.
    self.captureManager = [[AVCamCaptureManager alloc] init];
    self.captureManager.delegate = self;
    
    // create the camera button.
    [self createCameraButton];
}


- (BOOL)setupCaptureManager
{
    if ([self.captureManager setupSession]) {
        // Create video preview layer and add it to the UI
        AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureManager.session];
        newCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        newCaptureVideoPreviewLayer.frame        = self.bounds;
        [self.layer insertSublayer:newCaptureVideoPreviewLayer below:self.overlay];
        self.captureVideoPreviewLayer = newCaptureVideoPreviewLayer;
        
        return YES;
    }
    return NO;
}



#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // if the keypath recieved is for camera adjusting the focus then handle the focus change
    if ([keyPath isEqualToString:@"adjustingFocus"]) {
        [self focusStateChanged];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



#pragma mark - Setters & Getters

- (void)setHideCaptureButtonDuringCameraAdjustingFocus:(BOOL)hideCaptureButtonDuringCameraAdjustingFocus
{
    if (self.hideCaptureButtonDuringCameraAdjustingFocus != hideCaptureButtonDuringCameraAdjustingFocus) {
        _hideCaptureButtonDuringCameraAdjustingFocus = hideCaptureButtonDuringCameraAdjustingFocus;
        
        // add or remove the camera focus observer as appropriate.
        if (hideCaptureButtonDuringCameraAdjustingFocus) {
            [self addCameraFocusObserver];
        } else {
            [self removeCameraFocusObserver];
        }
    }
}

- (void)setOverlay:(CALayer *)overlay
{
    if (self.overlay != overlay) {
        [self.overlay removeFromSuperlayer];
        _overlay = nil;
        _overlay = overlay;
        [self.layer addSublayer:overlay];
    }
}

- (void)setCaptureButton:(ARCameraButton *)captureButton
{
    if (_captureButton != captureButton) {
        
        // if the existing camera button is a subview of the camera view; remove it so it will be released
        if (_captureButton.superview == self) {
            [_captureButton removeFromSuperview];
        }
        
        // remove the capture target/action for the old button
        [_captureButton removeTarget:self action:@selector(captureImage:) forControlEvents:UIControlEventTouchUpInside];
        
        
        _captureButton = captureButton;
        
        // check that the new button has a target/action for capturing an image and add one if not
        BOOL hasTarget = NO;
        for (NSString *selectorString in [_captureButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside]) {
            SEL selector = NSSelectorFromString(selectorString);
            if (sel_isEqual(selector, @selector(captureImage:))) {
                hasTarget = YES;
                break;
            }
        }
        if (!hasTarget) {
            [_captureButton addTarget:self action:@selector(captureImage:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        
        if (_captureButton == nil) {
            [self createCameraButton];
        }
    }
}



#pragma mark - Setup Failure

/** creates a label saying that starting the camera failed. */
- (void)createNoInputView
{
    // create a label that says the camera couldn't start and add to camera view.
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Couldn't start camera\nTap to retry";
    [self addSubview:label];
    
    // add tap recognizer to label that will attempt to retry to start the camera.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retrySetup:)];
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:tap];
}

/** creates a label saying that camera access permission is denied. */
- (void)createNoCameraPermissionView
{
    // create a label that says the camera couldn't start and add to camera view.
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Permission to access the camera has been denied\nYou can grant permission in the Settings app";
    [self addSubview:label];
    
    // add tap recognizer to label that will attempt to retry to start the camera.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retrySetup:)];
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:tap];
}

/** action for tap recogniser: attempts to start camera. */
- (void)retrySetup:(UITapGestureRecognizer *)tap
{
    // remove the error label from the camera view.
    [tap.view removeFromSuperview];
    
    // start camera.
    [self startCamera];
}



#pragma mark - Toggle Camera

- (void)toggleCamera
{
    BOOL success = [self.captureManager toggleCamera];
    if (success) {
        if ([self.delegate respondsToSelector:@selector(cameraViewDidChangeCamera:)]) {
            [self.delegate cameraViewDidChangeCamera:self];
        }
    }
}



#pragma mark - Camera Button Creation

+ (Class)cameraButtonClass
{
    return [ARCameraButton class];
}

/** Creates the camera shutter button using the classes cameraButtonClass add constraints and add it to the camera view. */
- (void)createCameraButton
{
    // get the class that the capture button should be & check that it is a subclass of ARCameraButton.
    Class cameraClass = [[self class] cameraButtonClass];
    NSAssert([cameraClass isSubclassOfClass:[ARCameraButton class]], @"The cameraButtonClass method must return either ARCameraButton or a subclass of that class");
    
    // create the button object.
    self.captureButton = [cameraClass buttonWithType:UIButtonTypeCustom];
    self.captureButton.hidden = YES;
    self.captureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.captureButton addTarget:self action:@selector(captureImage:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.captureButton];
    
    
    // constraint to keep button a set distance from bottom of camera view.
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.captureButton
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:-CAMERA_BUTTON_DISTANCE_FROM_BOTTOM];
    
    // constraint to horiziontally center the button in the camera view.
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.captureButton
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1.0
                                                                constant:0.0];
    
    
    // add the above constraints to keep the camera button in place.
    [self addConstraint:bottom];
    [self addConstraint:centerX];
}



#pragma mark - Camera Focus Handling

- (void)focusStateChanged
{
    
    AVCaptureDevice *device = self.captureManager.videoInput.device;
    self.captureButton.hidden = device.adjustingFocus;
}

/** add a KVO for the class observing if the capture device is adjusting its focus. If there already is one then it does nothing. */
- (void)addCameraFocusObserver
{
    // if the camera device supports auto focus then add an observer to when the camera is adjusting focus.
    if (!self.addedFocusKVO) {
        if ([_captureManager.videoInput.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [_captureManager.videoInput.device addObserver:self forKeyPath:@"adjustingFocus" options:kNilOptions context:NULL];
            self.addedFocusKVO = YES;
        }
    }
}

/** remove the KVO for the class observing if the capture device is adjusting its focus. If there isn't one then it does nothing. */
- (void)removeCameraFocusObserver
{
    // if observing the focus status of the video device then remove observer.
    if (self.addedFocusKVO) {
        [self.captureManager.videoInput.device removeObserver:self forKeyPath:@"adjustingFocus"];
        self.addedFocusKVO = NO;
    }
}



#pragma mark - Starting & Stopping Camera

- (void)startCamera
{
    // if the camera is already running then do nothing and return.
    if ([[self.captureManager session] isRunning]) return;
    
    // if there isn't a capture session then create one.
    if (![self.captureManager hasSession]) {
        BOOL success = [self setupCaptureManager];
        if (!success) {
            
            if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
                [self createNoCameraPermissionView];
            } else {
                [self createNoInputView];
            }
            
            return;
        }
    }
    
    // add the camera focus observer if required.
    if (self.hideCaptureButtonDuringCameraAdjustingFocus) {
        [self addCameraFocusObserver];
    }
    
    // if the connection can change orientation then set the current orientation.
    if ([self.captureVideoPreviewLayer.connection isVideoOrientationSupported]) {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationFromUIInterfaceOrientation([[UIApplication sharedApplication] statusBarOrientation]);
        [self.captureVideoPreviewLayer.connection setVideoOrientation:orientation];
    }
    
    // add an observer for the device rotating.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [notificationCenter addObserver:self
                           selector:@selector(deviceOrientationDidChange:)
                               name:UIDeviceOrientationDidChangeNotification
                             object:nil];
    
    // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {
                       [self.captureManager.session startRunning];
                       
                       dispatch_sync(dispatch_get_main_queue(), ^(void){
                           [self bringSubviewToFront:self.captureButton];
                           self.captureButton.hidden = NO;
                       });
                   });
}

- (void)stopCamera
{
    
    
    // if the camera isn't running then there is nothing to do so just return.
    if (![[_captureManager session] isRunning]) return;
    
    // remove the camera adjsuting focus observer if there is one.
    [self removeCameraFocusObserver];
    
    // remove the device rotation observer.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    // stop the session, this is done in a seperate queue and the method is synchronous and may take some time.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {
                       [[_captureManager session] stopRunning];
                       
                       dispatch_sync(dispatch_get_main_queue(), ^(void){
                           _imageTaken = nil;
                           self.captureButton.hidden = YES;
                       });
                   });
}

- (void)stopCameraAndSession
{
    // if there isn't a session then
    if (![self.captureManager hasSession]) return;
    
    // remove the camera adjsuting focus observer if there is one.
    [self removeCameraFocusObserver];
    
    // remove the device rotation observer.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    // stop and teardown the session, this is done in a seperate queue and the method is synchronous and may take some time.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [[self.captureManager session] stopRunning];
        [self.captureManager teardownSession];
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            self.imageTaken = nil;
            self.captureButton.hidden = YES;
        });
    });
}



#pragma mark - Resize Handling

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // set the bounds of the overlay layer.
    if (self.overlay) {
        self.overlay.frame = self.bounds;
    }
    
    // set the bounds of the preview layer.
    if (self.captureVideoPreviewLayer) {
        self.captureVideoPreviewLayer.frame = self.bounds;
    }
}



#pragma mark - Rotation Handling

/** handles the device orientation. Called from NSNotficationCenter. */
- (void)deviceOrientationDidChange:(NSNotification *)sender
{
    // if the connection can change orientation then set the current orientation.
    if ([self.captureVideoPreviewLayer.connection isVideoOrientationSupported]) {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationFromUIInterfaceOrientation([[UIApplication sharedApplication] statusBarOrientation]);
        [self.captureVideoPreviewLayer.connection setVideoOrientation:orientation];
    }
}



#pragma mark - Capturing Images

/** capture a still image. This method exists for the shutter button on the view and just calls -captureImage. */
- (void)captureImage:(id)sender
{
    // call the full capture image method.
    [self captureImage];
}


- (void)captureImage
{
    // if the camera is not running and an image is being displayed, remove the image and start the camera.
    if (![[_captureManager session] isRunning]) {
        self.captureButton.showingCancel = NO;
        [_imageView removeFromSuperlayer];
        [[_captureManager session] startRunning];
        return;
    }
    
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
    UIView *flashView = [[UIView alloc] initWithFrame:self.bounds];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:flashView];
    
    // animate the flash view them remove and stop camera.
    [UIView animateWithDuration:0.4f
                     animations:^{
                         [flashView setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                         self.captureButton.showingCancel = YES;
                         [[_captureManager session] stopRunning];
                     }
     ];
    
    // capture a still image from the camera. The actual image is received by the -captureManagerStillImageCaptured:image: delegate method.
    [self.captureManager captureStillImage];
}

- (void)removeTakenImage
{
    // remove image view
    [self.imageView removeFromSuperlayer];
    self.imageView = nil;
    
    // remove the captured images
    self.imageTaken      = nil;
    self.wholeImageTaken = nil;
    
    // restart the camera live capturing.
    if (![[self.captureManager session] isRunning]) {
        [[self.captureManager session] startRunning];
        self.captureButton.showingCancel = NO;
    }
}



#pragma mark - delegate stuff

- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}


- (void)captureManagerStillImageCaptured:(AVCamCaptureManager *)captureManager image:(UIImage *)image
{
    // the method recieves an uncropped image; set a the whole image.
    self.wholeImageTaken = image;
    
    // set the image to a cropped version.
    self.imageTaken = [image imageCroppedToAspectFillRect:self.bounds];
    
    // if there is no image view to display image then make one.
    if (self.imageView == nil) {
        self.imageView = [CALayer new];
        self.imageView.contentsGravity = kCAGravityResizeAspect;
    }
    
    // set up image view and add to camera view (below snap button as we need that to be visible)
    self.imageView.frame = self.bounds;
    self.imageView.contents = (__bridge id _Nullable)([self.imageTaken fixOrientation].CGImage);
    if (self.overlay && self.showOverlayOverCapturedImage) {
        [self.layer insertSublayer:self.imageView below:self.overlay];
    } else {
        [self.layer insertSublayer:self.imageView above:self.overlay];
    }
    
    // message the delegate that an iamge was taken.
    if ([self.delegate respondsToSelector:@selector(cameraView:hasTakenImage:)]) {
        [self.delegate cameraView:self hasTakenImage:_imageTaken];
    }
}

@end


//-----------------------------------------------------------------------------//
#pragma mark - Additions

@implementation ARCameraView (UsefulAdditions)

- (BOOL)hasImage
{
    return (self.imageTaken != nil);
}

@end


