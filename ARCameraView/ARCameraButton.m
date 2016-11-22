//
//  ARCameraButton.m
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

#import "ARCameraButton.h"

@implementation ARCameraButton

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(60, 60);
}


-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)setShowingCancel:(BOOL)showingCancel
{
    _showingCancel = showingCancel;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    [[UIColor whiteColor] setFill];
    CGContextFillEllipseInRect(context, self.bounds);
    [[UIColor blackColor] setFill];
    CGContextFillEllipseInRect(context, CGRectInset(self.bounds, 5.0, 5.0));
    if (self.highlighted) {
        [[UIColor darkGrayColor] setFill];
    } else {
        [[UIColor whiteColor] setFill];
    }
    CGContextFillEllipseInRect(context, CGRectInset(self.bounds, 7.0, 7.0));
    
    if (self.showingCancel) {
        
        UIColor *crossColor = (self.highlighted) ? [UIColor lightGrayColor] : [UIColor blackColor];
        [crossColor setStroke];
        
        UIBezierPath *crossPath = [UIBezierPath bezierPath];
        [crossPath moveToPoint:CGPointMake(20.0, 20.0)];
        [crossPath addLineToPoint:CGPointMake(40.0, 40.0)];
        [crossPath moveToPoint:CGPointMake(20.0, 40.0)];
        [crossPath addLineToPoint:CGPointMake(40.0, 20.0)];
        [crossPath setLineWidth:5.0];
        [crossPath stroke];
    }
    
    CGContextRestoreGState(context);
}

@end
