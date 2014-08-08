//
//  UIImage+AspectResize.m
//
//  Created by Adrian Russell on 07/08/2014.
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

#import "UIImage+AspectResize.h"

@implementation UIImage (AspectResize)

- (UIImage *)imageCroppedToAspectFillRect:(CGRect)aRect
{
    CGFloat sourceWidth  = self.size.width  * self.scale;
	CGFloat sourceHeight = self.size.height * self.scale;
    
	CGFloat targetWidth  = aRect.size.width;
	CGFloat targetHeight = aRect.size.height;
    
	// Calculate aspect ratios
	CGFloat sourceRatio = sourceWidth / sourceHeight;
	CGFloat targetRatio = targetWidth / targetHeight;
	
	// Determine what side of the source image to use for proportional scaling
	BOOL scaleWidth = (sourceRatio <= targetRatio);
	
	// Proportionally scale source image
	CGFloat scalingFactor, scaledWidth, scaledHeight;
	if (scaleWidth) {
		scalingFactor = 1.0 / sourceRatio;
		scaledWidth = targetWidth;
		scaledHeight = round(targetWidth * scalingFactor);
	} else {
		scalingFactor = sourceRatio;
		scaledWidth = round(targetHeight * scalingFactor);
		scaledHeight = targetHeight;
	}
	CGFloat scaleFactor = scaledHeight / sourceHeight;
	
	// Calculate compositing rectangles
	CGRect sourceRect;
    
    // Crop center
    CGFloat destX = round((scaledWidth - targetWidth) / 2.0);
    CGFloat destY = round((scaledHeight - targetHeight) / 2.0);
    sourceRect = CGRectMake(destX / scaleFactor, destY / scaleFactor, targetWidth / scaleFactor, targetHeight / scaleFactor);
    
    // the cropping doesn't work if the image is taken when the device is portrait so the sourceRect must be flipped else the cropping is done on the wrong axis.
    if (self.imageOrientation == UIImageOrientationLeft || self.imageOrientation == UIImageOrientationRight) {
        sourceRect = CGRectMake(sourceRect.origin.y, sourceRect.origin.x, sourceRect.size.height, sourceRect.size.width);
    }
    
    // create the cropped image using the sourceRect created.
    CGImageRef newImage = CGImageCreateWithImageInRect(self.CGImage, sourceRect);
    
    // create a UIImage from the cropped image.
    UIImage *finalImage = [UIImage imageWithCGImage:newImage scale:self.scale orientation:self.imageOrientation];
    
    // release the CGImage.
    CGImageRelease(newImage);
    
    return finalImage;
}


@end
