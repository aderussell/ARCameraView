//
//  ARViewController.m
//  ARCameraView
//
//  Created by Adrian Russell on 06/08/2014.
//  Copyright (c) 2014 Adrian Russell. All rights reserved.
//

#import "ARViewController.h"

@interface ARViewController ()
@property CALayer *overlayLayer;
@end

@implementation ARViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.cameraView startCamera];
    
    self.overlayLayer = [self createOverlayLayerForSize:self.cameraView.bounds.size];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.cameraView stopCameraAndSession];
}

- (void)willResignActive:(NSNotification *)notification
{
    [self.cameraView stopCamera];
}

- (void)didEnterForeground:(NSNotification *)notification
{
    [self.cameraView startCamera];
}

#pragma mark - IBActions

- (IBAction)toggleOverlay:(id)sender
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.overlayLayer.frame = self.cameraView.bounds;
    [CATransaction commit];
    self.cameraView.overlay = (self.overlaySwitch.isOn) ? self.overlayLayer : nil;
}

#pragma mark - Create Overlay

- (CALayer *)createOverlayLayerForSize:(CGSize)aSize
{
    UIGraphicsBeginImageContext(aSize);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(currentContext, 4);
    CGFloat phase[2] = {5,5};
    CGContextSetLineDash(currentContext, 0, phase, 2);
    CGContextSetStrokeColorWithColor(currentContext, [UIColor whiteColor].CGColor);
    CGContextStrokeRect(currentContext, CGRectInset(CGRectMake(0, 0, aSize.width, aSize.height), 20, 20));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    CALayer *layer = [CALayer new];
    layer.bounds = CGRectMake(0, 0, aSize.width, aSize.height);
    layer.contents = (__bridge id)(image.CGImage);
    layer.contentsGravity = kCAGravityResize;
    layer.opacity = 0.6;
    return layer;
}

@end
