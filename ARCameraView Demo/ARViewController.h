//
//  ARViewController.h
//  ARCameraView
//
//  Created by Adrian Russell on 06/08/2014.
//  Copyright (c) 2014 Adrian Russell. All rights reserved.
//

@import UIKit;
#import "ARCameraView.h"

@interface ARViewController : UIViewController
@property (weak) IBOutlet ARCameraView *cameraView;
@property (weak) IBOutlet UISwitch     *overlaySwitch;
@end
