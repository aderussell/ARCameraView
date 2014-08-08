//
//  CameraButton.h
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

/** 
 This class is the base class for the shutter button used in ARCameraView.
 It adds an additional attribute; showingCancel. This attribute is used by ARCameraView to stop showing the taken image and go back to the main camera mode.
 
 You can subclass this class and reimplement -drawRect: to add a custom look. To make ARCameraView use your custom button subclass, subclass ARCameraView and override the +cameraButtonClass method to return your custom button class; when an instance your camera subclass is initialised it will use your custom shutter button class.
 */
IB_DESIGNABLE
@interface ARCameraButton : UIButton
/** Whether, or not, the button should present itself to close the image (YES) or to capture and image from the camera (NO). */
@property (nonatomic, getter=isShowingCancel) IBInspectable BOOL showingCancel;
@end
