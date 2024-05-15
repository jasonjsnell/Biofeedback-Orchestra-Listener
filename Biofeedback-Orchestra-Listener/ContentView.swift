//
//  ContentView.swift
//  Biofeedback-Orchestra-Listener
//  Created by Jason Snell on 4/24/24.

import SwiftUI

struct ContentView: View {
    @StateObject var multipeerSessionManager = MultipeerSessionManager()
    
    // Define the layout for the grid
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    // vars to track the ABLink view controller
    @State private var showAbletonLinkView = false
    @StateObject private var ablinkVCW = ABLinkViewControllerWrapper()
    @State private var averageBpm: Int = 0
    
    var body: some View {
        VStack {
            Text("PULSES")
                .font(.system(size: 48))
                .padding(.top, 40)
            Text("BIOFEEDBACK ORCHESTRA")
                .font(.system(size: 24))
                .padding(.bottom, 25)
            
            Text("Connected Musicians:")
                .font(.system(size: 18))
                .padding(.bottom)
            
            
            HStack(spacing: 20) {
                VStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        let slot = multipeerSessionManager.midiSlots[index]
                        MIDISlotView(slot: $multipeerSessionManager.midiSlots[index])
                            .frame(width: 200, height: 75)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(slot.device != nil ? Color.white : Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: slot.device != nil ? [] : [5]))
                            )
                            .onTapGesture {
                                //send midi pulse for midi mapping
                                multipeerSessionManager.sendAlphaMidiPulse(toChannel: index)
                            }
                            .onDrag {
                                NSItemProvider(object: String(slot.id) as NSString)
                            }
                            .onDrop(of: [.text], delegate: MIDISlotDropDelegate(targetSlot: $multipeerSessionManager.midiSlots[index].wrappedValue, midiSlots: $multipeerSessionManager.midiSlots))
                    }
                }
                
                VStack(spacing: 20) {
                    ForEach(4..<8, id: \.self) { index in
                        let slot = multipeerSessionManager.midiSlots[index]
                        MIDISlotView(slot: $multipeerSessionManager.midiSlots[index])
                            .frame(width: 200, height: 75)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(slot.device != nil ? Color.white : Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: slot.device != nil ? [] : [5]))
                            )
                            .onTapGesture {
                                //send midi pulse for midi mapping
                                multipeerSessionManager.sendAlphaMidiPulse(toChannel: index)
                            }
                            .onDrag {
                                NSItemProvider(object: String(slot.id) as NSString)
                            }
                            .onDrop(of: [.text], delegate: MIDISlotDropDelegate(targetSlot: $multipeerSessionManager.midiSlots[index].wrappedValue, midiSlots: $multipeerSessionManager.midiSlots))
                    }
                }
                
                VStack(spacing: 20) {
                    ForEach(8..<10, id: \.self) { index in
                        let slot = multipeerSessionManager.midiSlots[index]
                        MIDISlotView(slot: $multipeerSessionManager.midiSlots[index])
                            .frame(width: 200, height: 75)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(slot.device != nil ? Color.white : Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: slot.device != nil ? [] : [5]))
                            )
                            .onTapGesture {
                                //send midi pulse for midi mapping
                                multipeerSessionManager.sendAlphaMidiPulse(toChannel: index)
                            }
                            .onDrag {
                                NSItemProvider(object: String(slot.id) as NSString)
                            }
                            .onDrop(of: [.text], delegate: MIDISlotDropDelegate(targetSlot: $multipeerSessionManager.midiSlots[index].wrappedValue, midiSlots: $multipeerSessionManager.midiSlots))
                    }
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
                    .font(.system(size: 18))
                    .foregroundColor(.white)
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
