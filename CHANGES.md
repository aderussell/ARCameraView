1.0.2 (In Progress)
-------------------

#### Fixed
* Overlay layer is now correctly shown if it is added to the view before the camera is started.
* The delegate method for the view weill not be incorrectly called if an image is not captured by the camera when the camera button is pressed.


1.0.1 (22/11/2016)
------------------

#### Changed
* Exposed the `captureButton` property which allows the button to be manipulated or changed.
* `ARCameraButton` now has an intrinsic content size rather than having the camera view hard code the size.

#### Fixed
* The capture session is now stopped and the captured image immediately after the image has been captured rather than after the delegate method returns. This makes using the camera easier while debugging an app.



1.0.0 (15/12/2014)
------------------
* Added message if camera permission is denied
* fixed error in Xcode 6
