#ARCameraView
A dropin view component for iOS that gives access to the device caerma and allows photos to be captured



## Using ARCameraView
An instance of a camera view can be created either in Interface Builder or by using `-initWithFrame`:
It should be noted that the camera does not start automatically; start the camera by calling the `-startCamera` method.

It is good practise to stop the camera whenever it is not directly in use, this includes when the app goes to background. 
The best way to achieve this is for the managing viewcontroller to recieve notifications for your app entering the background or foreground and calling `-stopCameraAndSession` and `-startCamera` respectively. 

The camera view has a shutter button on the view that can be pressed by the user to take a photograph. The photograph is then displayed in the camera view. Pressing the shutter button again will dismiss the photograph and restart the camera.
By default the shutter button is hidden when the camera is adjusting focus to avoid taking blurry photos although this behaviour can be removed by setting the property `hideCaptureButtonDuringCameraAdjustingFocus` to `NO`.

### Overlay
It is possible to add an overlay to the camera view. This should be to give the camera a grid, or someother relevant guide to help align photos.
The overlay takes the form of a CALayer sized to the bounds of the camera view assigned to the `overlay` property.
To remove the overlay set the property to `nil`.


### Camera view events
The camera view has a delegate that can be used to receive notifications that a photo has been captured.

### Subclassing camera view and camera button
If you wish to use a custom shutter button on the camera view then that is possible by subclassing both ARCameraButton and ARCameraView.
The only method that should be overwritten in ARCameraButton is `-drawRect:` and the button must be 60px-60px in size.
In the ARCameraview subclass overwrite the method `+cameraButtonClass` to return the name of your new button class.
