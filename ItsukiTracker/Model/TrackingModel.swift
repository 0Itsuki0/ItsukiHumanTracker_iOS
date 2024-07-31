//
//  TrackingModel.swift
//  ItsukiTracker
//
//  Created by Itsuki on 2024/07/31.
//

import SwiftUI
import Vision

struct TrackableObject: Identifiable {
    var id: Int
    var rect: CGRect
    var firstDetect: Date = Date()
    var lastDetect: Date = Date()
    
    var totalDetectionTime: Float {
        return Float(lastDetect.timeIntervalSince(firstDetect))
    }

}

class TrackingModel: ObservableObject {
    let vision = VisionManager()
    let camera = CameraManager()
    let tracker = CentroidTracker(maxDisappearedFrameCount: 10, maxNormalizedDistance: 0.2)
    
    @Published var previewImage: CIImage?

    @Published var trackedObjects: [TrackableObject] = []
    @Published var deregisteredObjects: [TrackableObject] = []
    
    var averageTrackedTime: Float {
        if trackedObjects.isEmpty && deregisteredObjects.isEmpty {
            return 0.0
        }
        
        let currentlyTrackingTotal = trackedObjects.map({$0.totalDetectionTime}).reduce(0, +)
        let deregisteredTotal = deregisteredObjects.map({$0.totalDetectionTime}).reduce(0, +)
        let average = (currentlyTrackingTotal + deregisteredTotal) / Float(trackedObjects.count + deregisteredObjects.count)
        return average
    }
    
    @Published var isTracking: Bool = false {
        willSet(newValue) {
            if newValue {
                trackedObjects = []
            }
        }
        
        didSet {
            if isTracking {
                if framePerSecond > 0 {
                    self.canProcess = true
                    self.timer = Timer.scheduledTimer(timeInterval: 1.0/framePerSecond, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
                }
            } else {
                timer?.invalidate()
            }
        }
    }
    
    var framePerSecond: Double = 0 {
        willSet {
            if newValue < 0 {
                self.framePerSecond = 0
            } else {
                self.framePerSecond = min(newValue, maxFramePerSecond)
            }
        }
        
        didSet {
            if isTracking {
                if framePerSecond > 0 {
                    self.timer = Timer.scheduledTimer(timeInterval: 1.0/framePerSecond, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
                } else {
                    timer?.invalidate()
                }
            }
        }
    }
    
    let maxFramePerSecond: Double = 20
    
    // for processing based on FPS
    private var canProcess: Bool = false
    private var timer: Timer? = nil
    
    private var frameSize: CGSize = .zero
    private let thresholdConfidence: Float = 0.0
    
    init() {
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleVisionObservations()
        }
    }
    
    
    private func handleCameraPreviews() async {
        for await ciImage in camera.previewStream {
            Task { @MainActor in
                previewImage = ciImage
//                
//                // Continuous processing
//                if isDetecting, framePerSecond <= 0 {
//                    vision.processLiveDetection(ciImage)
//                }
                if isTracking && ((framePerSecond > 0 && canProcess) || framePerSecond <= 0) {
                    canProcess = false
                    vision.processHumanDetection(ciImage)
                }
            }
        }
    }
    
    
    private func handleVisionObservations() async {
        for await observations in vision.observationStream {
            Task { @MainActor in
//                if isDetecting || mode == .still{
//                    self.observations = observations
//                }
                if isTracking {
                    processObservations(observations)
                }
            }
        }
    }
    



    @MainActor
    func processObservations(_ observations: [HumanObservation]) {
        let boundingBoxes = observations.filter({$0.confidence > thresholdConfidence}).map({$0.boundingBox})
        tracker.update(rects: boundingBoxes)
        
        let currentTrackedObject = self.trackedObjects
        
        let updatedTrackedRects = tracker.objects
        let rectsInFrame = tracker.objectsInFrame
        let deregisteredObjectsId = tracker.deregisteredObjects
        
        
        // update deregistered object
        let newlyDeregisteredObjects = currentTrackedObject.filter({deregisteredObjectsId.contains($0.id)})

        self.deregisteredObjects.append(contentsOf: newlyDeregisteredObjects)
//        print("deregistering \(newlyDeregisteredObjects.count) objects")
        
        // update tracked objects
        trackedObjects.removeAll(where: {deregisteredObjectsId.contains($0.id)})
        
        for rect in updatedTrackedRects {
            let firstTrackedIndex = trackedObjects.firstIndex(where: {$0.id == rect.key})
            
            // temporarily disappeared objects
            if !rectsInFrame.contains(where: {$0.key == rect.key}) {
//                print("temporarily not in frame: \(rect.key)")
                if let firstTrackedIndex = firstTrackedIndex {
                    self.trackedObjects[firstTrackedIndex].rect = .zero
                    self.trackedObjects[firstTrackedIndex].lastDetect = Date()
                }
                continue
            }

            // convert normalized rect to imageCoordinate
            let convertedRect = rect.value.toImageCoordinates(frameSize, origin: .upperLeft)

            if let firstTrackedIndex = firstTrackedIndex {
//                print("tracked: updating \(rect.key)")
                self.trackedObjects[firstTrackedIndex].rect = convertedRect
                self.trackedObjects[firstTrackedIndex].lastDetect = Date()
            } else {
//                print("not tracked: adding \(rect.key)")
                self.trackedObjects.append(TrackableObject(id: rect.key, rect: convertedRect))
            }
        }

    }
    
    func setFrameSize(_ size: CGSize) {
        self.frameSize = size
    }
    
    // Processing based on FPS specified
    @objc private func timerFired() {
        canProcess = true
    }

}
