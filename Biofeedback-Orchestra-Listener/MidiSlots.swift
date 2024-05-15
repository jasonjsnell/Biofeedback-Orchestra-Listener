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
    var device: ConnectedDevice?  // Reference to the connected device
}

struct MIDISlotView: View {
    @Binding var slot: MIDISlot  // Now expects a binding to a MIDISlot

    var body: some View {
        VStack {
            if let device = slot.device {
                Text(device.peerID.displayName) // Display the device's name
                    .font(.system(size: 18)) // Smaller font size
                    .multilineTextAlignment(.center) // Center text
            } else {
                Text("MIDI Ch \(slot.id)") // Display MIDI channel if no device
                    .font(.system(size: 18))
            }
        }
        .padding() // Add some padding for better spacing
        .frame(width: 200, height: 75) // Specify frame size
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 1) // Border for the slot
        )
    }
}







struct MIDISlotDropDelegate: DropDelegate {
    var targetSlot: MIDISlot
    @Binding var midiSlots: [MIDISlot]

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let string = String(data: data, encoding: .utf8),
                  let sourceID = Int(string),
                  let sourceIndex = midiSlots.firstIndex(where: { $0.id == sourceID }),
                  let targetIndex = midiSlots.firstIndex(where: { $0.id == targetSlot.id }) else {
                return
            }
            
            DispatchQueue.main.async {
                // Transfer the device to the new slot
                let movingDevice = midiSlots[sourceIndex].device
                midiSlots[sourceIndex].device = nil
                midiSlots[targetIndex].device = movingDevice
                
                // Update the device's position to reflect its new MIDI channel
                movingDevice?.update(position: targetSlot.id)
            }
        }
        
        return true
    }
}
