//
//  VisionManager.swift
//  ItsukiTracker
//
//  Created by Itsuki on 2024/07/31.
//


import SwiftUI
import Vision


class VisionManager {

    private var request: DetectHumanRectanglesRequest
    
    private var isProcessing: Bool = false
    private var addToObservationStream: (([HumanObservation]) -> Void)?
    
    lazy var observationStream: AsyncStream<[HumanObservation]> = {
        AsyncStream { continuation in
            addToObservationStream = { observations in
                continuation.yield(observations)
            }
        }
    }()
    
    
    init() {
        var request = DetectHumanRectanglesRequest()
        request.upperBodyOnly = true // requires only detecting a human upper body to produce a result.
        self.request = request
    }
    
    
    func processHumanDetection(_ ciImage: CIImage) {
        print("processing: \(isProcessing)")

        if isProcessing { return }
        isProcessing = true
        defer {
            isProcessing = false
        }
        print("processing")

        Task {
            guard let observations = try? await request.perform(on: ciImage) else {
                print("human detection request failed")
                return
            }
            print("observations: \(observations.count)")
            addToObservationStream?(observations)
        }
    }
}
