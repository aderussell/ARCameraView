//
//  ARCameraView.h
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

@import UIKit;
#import "ARCameraButton.h"

@class ARCameraView;


/**
 The delegate for ARCameraView. This gives a way for an external object to receive notification of events that occured on the camera view such as an photo being taken.
 */
@protocol ARCameraViewDelegate <NSObject>
@optional

/**
 Tells the delegate that can image has been captured on the camera view.
 @param cameraView The camera view object informing the delegate.
 @param image      The image that was captured by the camera view.
 */
- (void)cameraView:(ARCameraView *)cameraView hasTakenImage:(UIImage *)image;

/**
 Tells the delegate that can camera view has changed the device camera that is being captured.
 @param cameraView The camera view object informing the delegate.
 */
- (void)cameraViewDidChangeCamera:(ARCameraView *)cameraView;

@end




//---------------------------------------------------------------------------------
#pragma mark - CameraView Class interface

/**
 This class is a custom view that can take photos from the device camera.
 */
@interface ARCameraView : UIView

/**
 Returns the class used to create the camera button for instances of this class.
 @return The class used to create the view’s shutter camera button.
 @discussion This method returns the ARCameraButton class object by default. Subclasses can override this method and return a different class as needed but the specified class must be a subclass of ARCameraButton; failing to do this will cause an assertion. This method is called only once early in the creation of the view in order to create the corresponding shutter button.
 */
+ (Class)cameraButtonClass;

/** The receiver's delegate. */
@property (weak) id<ARCameraViewDelegate> delegate;

/** An overlay to place over the camera preview. This is not displayed when showing the taken image. To remove set to `nil`.*/
@property (nonatomic) CALayer *overlay;

/** @name Images */

/** The image taken as seen in the view. `nil` if no image taken. */
@property (readonly) UIImage *imageTaken;

/** The entire image taken by camera. depending on view ratio may contain more image. `nil` if no image taken. */
@property (readonly) UIImage *wholeImageTaken;



/** @name Controlling Camera */

/** Remove the image that has been captured and restart the camera. */
- (void)removeTakenImage;

/** Capture an image and display. This is equivalent to pressing the cpture button on the view. */
- (void)captureImage;

/** Start the camera live capturing. This needs to be done to start the camera; it's not automatically done. */
- (void)startCamera;

/** Stop the camera live capturing. */
- (void)stopCamera;

/** Stop the camera live capturing and release the session. This should be done when the camera is not in use. */
- (void)stopCameraAndSession;

/** Toggle the device camera being used. If the device only has one camera then this method will do nothing.
 @discussion At the moment this method does nothing.
 */
- (void)toggleCamera;

/** Whether, or not, the capture button is hidden while the camera is adjusting the focus. The default is `YES`. */
@property (nonatomic) BOOL hideCaptureButtonDuringCameraAdjustingFocus;

/** The button that is pressed to capture an image. */
@property (nonatomic) ARCameraButton *captureButton;

@end


@interface ARCameraView (UsefulAdditions)

/** 
 * Whether, or not, the camera view has an image taken. 
 */
- (BOOL)hasImage;

@end

