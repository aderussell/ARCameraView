#
#  Be sure to run `pod spec lint ARCameraView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "ARCameraView"
  s.version      = "1.0.1"
  s.summary      = "A drop-in view for iOS that gives access to the device cameras and allows photos to be captured."
  s.description  = "A drop-in view for iOS that gives access to the device cameras and allows photos to be captured. This enables photos to be captured from ny view controller without having to present UIImagePickerViewController as another separate view controller."

  s.homepage     = "https://github.com/aderussell/ARCameraView"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT"

  s.author             = { "aderussell" => "adrianrussell@me.com" }
  s.social_media_url   = "http://twitter.com/ade177"

  s.platform     = :ios, "7.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/aderussell/ARCameraView.git", :tag => s.version.to_s }

  s.source_files  = "ARCameraView/*"
  # s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"



  s.frameworks = "UIKit", "AVFoundation", "MobileCoreServices", "ImageIO"

end
