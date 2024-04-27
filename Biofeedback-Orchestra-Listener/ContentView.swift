//
//  ContentView.swift
//  Biofeedback-Orchestra-Listener
//  Created by Jason Snell on 4/24/24.

import SwiftUI

struct ContentView: View {
    @StateObject var multipeerSessionManager = MultipeerSessionManager()
    
    // Define the layout for the grid
    let gridItems = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        
    
    @State private var averageBpm: Int = 0
        
    var body: some View {
        VStack {
            Text("Listener")
                .font(.largeTitle)
                .padding()
            
            Text("Connected Musicians:")
            
            
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach(multipeerSessionManager.midiSlots) { slot in
                    MIDISlotView(slot: slot)
                        .frame(width: 150, height: 75)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(slot.peerID != nil ? Color.white : Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: slot.peerID != nil ? [] : [5]))
                        )
                        .onDrag {
                            // Provide the data to be dragged
                            return NSItemProvider(object: String(slot.id) as NSString)
                        }
                        .onDrop(of: [.text], delegate: MIDISlotDropDelegate(targetSlot: slot, midiSlots: $multipeerSessionManager.midiSlots))
                }
            }
            
            Spacer()
            
            // Display the average BPM
            Text("Average BPM: \(averageBpm)")
                .padding()
        }
        .onReceive(multipeerSessionManager.bpmProcessor.$averageBpm) { newValue in
            averageBpm = newValue
        }
    }
}



