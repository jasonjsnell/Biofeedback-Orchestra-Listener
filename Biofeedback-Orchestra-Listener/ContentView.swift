//
//  ContentView.swift
//  Biofeedback-Orchestra-Listener
//  Created by Jason Snell on 4/24/24.

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject var multipeerSessionManager = MultipeerSessionManager()
    
    // Define the layout for the grid
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]

    
    //vars to track the ABLink view controller
    @State private var showAbletonLinkView = false
    @StateObject private var ablinkVCW = ABLinkViewControllerWrapper()
        
       
    
    @State private var averageBpm: Int = 0
        
    var body: some View {
        VStack {
            Text("Listener")
                .font(.largeTitle)
                .padding()
            
            Text("Connected Musicians:")
            
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach($multipeerSessionManager.midiSlots) { $slot in
                    MIDISlotView(slot: $slot)
                        .frame(width: 175, height: 75)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(slot.device != nil ? Color.white : Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: slot.device != nil ? [] : [5]))
                        )
                        .onDrag {
                            NSItemProvider(object: String(slot.id) as NSString)
                        }
                        .onDrop(of: [.text], delegate: MIDISlotDropDelegate(targetSlot: $slot.wrappedValue, midiSlots: $multipeerSessionManager.midiSlots))
                }
            }


            
            Spacer()
            
            // Display the average BPM
            
            Button(action: {
                // Create and present the Ableton Link view controller
                if let vc = multipeerSessionManager.bpmProcessor.getABLinkViewController() {
                    ablinkVCW.viewController = vc
                    showAbletonLinkView = true
                }
            }) {
                Text("Average BPM: \(averageBpm)")
            }
            .sheet(isPresented: $showAbletonLinkView) {
                if let vc = ablinkVCW.viewController {
                    ABLinkViewController(viewController: vc)
                }
            }
            
            .padding()
        }
        .onReceive(multipeerSessionManager.bpmProcessor.$averageBpm) { newValue in
            averageBpm = newValue
        }
    }
    
}



