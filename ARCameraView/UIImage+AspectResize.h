//
//  UIImage+AspectResize.h
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

#import <UIKit/UIKit.h>

@interface UIImage (AspectResize)

/** Creates a new image using the input image that is cropped so that appears and it would appear in a UIImageView with contentMode `UIViewContentModeScaleAspectFill`.
 @param aRect The rect to scale image to.
 @return A new UIImage object that contains an image as the input image would look in a UIImageView with contentMode `UIViewContentModeScaleAspectFill`.
 */
- (UIImage *)imageCroppedToAspectFillRect:(CGRect)aRect;

@end
