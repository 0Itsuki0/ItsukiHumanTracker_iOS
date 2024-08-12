# iOS Human Tracker

This is a real-time Human traffic tracker using Vision framework.<br>

If you are looking for a MacOS App for analyzing Human traffic using existing videos, please checkout [ItsukiHumanTrafficAnalyzer_macOS](https://github.com/0Itsuki0/ItsukiHumanTrafficAnalyzer_macOS).

------
While tracking, a preview of the camera and the following data will be displayed.

- The number of object currently tracked
- Disappeared object count
- Average time in second that an object is tracked.


You can tune the following parameters based on your needs.

- **FPS for processing**: When set to 0, processing continuously
- **Max Disappeared Frame Count**: If an object is not detected for a frame count greater this value, will be considered as disappeared.
- **Max Normalized Distance**: If the centroid of 2 detected objects in 2 consecutive frames is larger than this value, they will be considered as different objects


For further detail, please refer to [Swift/iOS: Real Time Human Traffic Tracker](https://medium.com/@itsuki.enjoy/swift-ios-real-time-human-traffic-tracker-01f1f6ade3f3).


## Prerequisite to Run
- [Xcode 16 beta](https://developer.apple.com/download)
- iOS 18 running on real device.


## Demo
A demo can be found in [TrackingDemoView](./ItsukiTracker/View/TrackingDemoView.swift).


![Demo](./ReadmeAsset/trackingDemo.gif)
