//
//  TrackingDemoView.swift
//  ItsukiTracker
//
//  Created by Itsuki on 2024/07/31.
//


import SwiftUI

struct TrackingDemoView: View {
    @StateObject private var trackingModel = TrackingModel()
    @State private var imageSize: CGSize = .zero
    @State private var sliderValue: Double = .zero

    private let boundingBoxPadding: CGFloat = 4.0
    private let asset = NSDataAsset(name: "humanWalking")
    
    @State private var gifImage: Image?
    
    
    var body: some View {
        
        VStack(spacing: 16) {
            gifImage?
                .resizable()
                .scaledToFit()
                .overlay(content: {
                    GeometryReader { geometry in
                        DispatchQueue.main.async {
                            self.imageSize = geometry.size
                        }
                        return Color.clear
                    }
                })
                .overlay(content: {
                    if trackingModel.isTracking {
                        ForEach(trackingModel.trackedObjects) { object in
                            let rect = object.rect
                            if rect != .zero {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.black, style: .init(lineWidth: 4.0))
                                    .frame(width: rect.width + boundingBoxPadding*2, height: rect.height + boundingBoxPadding*2)
                                    .position(CGPoint(x: rect.midX, y: rect.midY))

                            }
                        }
                    }
                })
            
            
            Spacer()
                .frame(height: 16)
            
            Button(action: {
                trackingModel.isTracking.toggle()
            }, label: {
                Text("\(trackingModel.isTracking ? "Stop" : "Start") Tracking")
                    .foregroundStyle(.black)
                    .padding(.all)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black, lineWidth: 2.0))
            })
                        
            VStack(spacing: 16) {
                Text("Tracked Object Overview")
                
                Divider()
                    .background(.black)
                
                Text("Currently Tracking: \(trackingModel.trackedObjects.count)")
                
                Text("Disappeared: \(trackingModel.deregisteredObjects.count)")

                Text("Average Tracked Time: \(String(format: "%.2f", trackingModel.averageTrackedTime)) sec")

            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.black, lineWidth: 2.0)
            )

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 32)
        .onAppear {
            if let asset {
                let gifData = asset.data as CFData
                CGAnimateImageDataWithBlock(gifData, nil) { index, cgImage, stop in
                    self.gifImage = Image(uiImage: .init(cgImage: cgImage))
                    if trackingModel.isTracking {
                        trackingModel.vision.processHumanDetection(CIImage(cgImage: cgImage))
                    }

                }
            }
        }
        .onDisappear {
            trackingModel.isTracking = false
        }
        .onChange(of: imageSize, {
            trackingModel.setFrameSize(imageSize)
        })

    }
    
}

#Preview {
    TrackingDemoView()
}
