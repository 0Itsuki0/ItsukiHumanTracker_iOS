//
//  ContentView.swift
//  ItsukiTracker
//
//  Created by Itsuki on 2024/08/11.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack (spacing: 50) {
            
            NavigationLink {
                TrackingDemoView()
            } label: {
                Text("Demo")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.black))
            }
            
            NavigationLink {
                LiveTrackingView()
            } label: {
                Text("Live Tracking")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.black))
            }

        }
        .foregroundStyle(.white)
        .font(.system(size: 24))
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    return NavigationStack {
        ContentView()
    }
}
