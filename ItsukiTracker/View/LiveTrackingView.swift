//
//  LiveTrackingView.swift
//  ItsukiTracker
//
//  Created by Itsuki on 2024/07/31.
//


import SwiftUI

struct LiveTrackingView: View {
    @StateObject private var trackingModel = TrackingModel()
    @State private var imageSize: CGSize = .zero
    @State private var sliderValue: Double = .zero

    private let boundingBoxPadding: CGFloat = 4.0
    private let asset = NSDataAsset(name: "humanWalking")
    
    @State private var showSetting: Bool = false

    
    var body: some View {
        
        VStack(spacing: 16) {
            if let image = trackingModel.previewImage?.image {
                image
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
            } else {
                Rectangle()
                    .fill(.black.opacity(0.8))
                    .aspectRatio(0.8, contentMode: .fill)
                    .padding()
            }
            
            
            Spacer()
                .frame(height: 8)
          
            
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
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .padding(.all, 32)
        .padding(.top, 16)
        .onTapGesture {
            showSetting = false
        }
        .overlay(alignment: .topTrailing, content: {
            Button(action: {
                showSetting.toggle()
            }, label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray)
                    .padding()
            })
        })
        .overlay(alignment: .top, content: {
            if showSetting {
                SettingView(showSetting: $showSetting)
                    .padding(.top, 32)
                    .environmentObject(trackingModel)
            }
        })
        .task {
            await trackingModel.camera.start()
        }
        .onDisappear {
//            trackingModel.camera.isPreviewPaused = true
            trackingModel.isTracking = false
            trackingModel.camera.stop()
        }
        .onChange(of: imageSize, {
            trackingModel.setFrameSize(imageSize)
        })
    }
    
}




fileprivate struct SettingView: View {
    @EnvironmentObject private var trackingModel: TrackingModel
    
    @Binding var showSetting: Bool
    @State private var framePerSecond: Double = .zero
    @State private var frameCount: Int = 0
    @State private var distance: Float = 0
    @FocusState private var focusedInput: Int?
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Slider(
                    value: $framePerSecond,
                    in: 0...trackingModel.maxFramePerSecond,
                    step: 0.5,
                    onEditingChanged: {changing in
                        guard !changing else {return}
                        trackingModel.framePerSecond = framePerSecond
                    }
                )
                .padding(.horizontal, 16)
                
                Text("FPS for processing: \(String(format: "%.1f", framePerSecond))")
                
                Text("When FPS is 0, processing continuously.")
                    .foregroundStyle(.red)

            }
            
            Divider()
                .background(.black)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Max Disappeared Frame Count.")
                        .frame(maxWidth: .infinity)
                    TextField("20", value: $frameCount, format: .number)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($focusedInput, equals: 0)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.yellow.opacity(0.2))
                        )
                        .padding(.horizontal)
                        
                }
                
                Text("To deregister a tracked object. \nValue greater than 0.")
                    .foregroundStyle(.red)

            }
            
            Divider()
                .background(.black)

            VStack(spacing: 16) {
                HStack {
                    Text("Max Normalized Distance")
                        .frame(maxWidth: .infinity)
                    TextField("0.2", value: $distance, format: .number)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .focused($focusedInput, equals: 1)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.yellow.opacity(0.2))
                        )
                        .padding(.horizontal)
                        
                }
                
                Text("To consider 2 detected objects in 2 consecutive frames to be different objects. \nValue within 0 to sqrt(2).")
                    .foregroundStyle(.red)
            }
            
            
        }
        .padding(.all, 24)
        .padding(.top, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .fill(.yellow.opacity(0.2))
                .stroke(.gray.opacity(0.5), style: .init(lineWidth: 2.0))
        )
        .overlay(alignment: .topTrailing, content: {
            Button(action: {
                showSetting = false
            }, label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .padding(.all, 4)
                    .background(Circle().fill(.gray.opacity(0.5)))
                    .padding()
            })
        })
        .onTapGesture {
            focusedInput = nil
        }
        .padding(.all, 24)
        .onAppear {
            self.framePerSecond = trackingModel.framePerSecond
            self.frameCount = trackingModel.tracker.maxDisappearedFrameCount
            self.distance = Float(trackingModel.tracker.maxNormalizedDistance)
        }
        .onChange(of: frameCount, {
            if frameCount <= 0 {
                self.frameCount = trackingModel.tracker.maxDisappearedFrameCount
            } else {
                trackingModel.tracker.maxDisappearedFrameCount = self.frameCount
            }
        })
        .onChange(of: distance, {
            if distance > sqrt(2) {
                self.distance = sqrt(2)
                trackingModel.tracker.maxNormalizedDistance = sqrt(2)
            } else if distance <= 0 {
                self.distance = 0
                trackingModel.tracker.maxNormalizedDistance = 0
            } else {
                trackingModel.tracker.maxNormalizedDistance = CGFloat(self.distance)
            }
        })
    }
}




#Preview {
    LiveTrackingView()
}
