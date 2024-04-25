//
//  ContentView.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/24/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var multipeerSessionManager = MultipeerSessionManager()

    var body: some View {
        VStack {
            Text("Listener")
                .font(.largeTitle)
                .padding()

            Text("Connected Musicians:")
            List {
                ForEach(multipeerSessionManager.connectedPeers, id: \.self) { peer in
                    Text(peer.displayName)
                }
            }
            
            // Display incoming EEG data here
            
            Button("Start Listening") {
                print("start listening")
                multipeerSessionManager.startAdvertising()
            }
            .padding()
        }
    }
}
