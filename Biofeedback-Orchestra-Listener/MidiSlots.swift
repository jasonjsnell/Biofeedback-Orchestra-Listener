//
//  MidiSlots.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/27/24.
//

import SwiftUI
import MultipeerConnectivity
import UniformTypeIdentifiers

struct MIDISlot: Identifiable {
    var id: Int    // Unique identifier for the slot
    var peerID: MCPeerID?  // Optional peerID of the connected device
}

struct MIDISlotView: View {
    let slot: MIDISlot

    var body: some View {
        VStack {
            if let peerID = slot.peerID {
                Text(peerID.displayName)
                    .font(.system(size: 13)) // Smaller font size
                    .multilineTextAlignment(.center) //center text
                    
            } else {
                Text("MIDI Ch \(slot.id)")
                  
            }
        }
    }
}


struct MIDISlotDropDelegate: DropDelegate {
    var targetSlot: MIDISlot
    @Binding var midiSlots: [MIDISlot]
    
    func performDrop(info: DropInfo) -> Bool {
        // Identify the provider for the dragged type
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        // Load the item from the provider
        itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier as String, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let string = String(data: data, encoding: .utf8),
                  let sourceID = Int(string),
                  let sourceIndex = midiSlots.firstIndex(where: { $0.id == sourceID }) else {
                return
            }
            
            DispatchQueue.main.async {
                // Swap the contents of the source slot with the target slot
                let sourceSlot = midiSlots[sourceIndex]
                if let targetIndex = midiSlots.firstIndex(where: { $0.id == targetSlot.id }) {
                    midiSlots[sourceIndex] = midiSlots[targetIndex]
                    midiSlots[targetIndex] = sourceSlot
                }
            }
        }
        
        return true
    }
}
