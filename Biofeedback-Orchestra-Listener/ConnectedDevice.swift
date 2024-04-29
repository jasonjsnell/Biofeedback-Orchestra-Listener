//
//  MusicianPeer.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/24/24.
//

import Foundation
import MultipeerConnectivity
import XvMidi

protocol ConnectedDeviceDelegate: AnyObject {
    func didDetect(newAlphaNote: UInt8, forChannel: UInt8)
    func didReceive(newAlphaCCValue:UInt8, forChannel: UInt8)
}

class ConnectedDevice:Identifiable {
    
    weak var delegate: ConnectedDeviceDelegate?
    var peerID: MCPeerID
    var position:Int
    var midiTimer:Timer?
    
    init(peerID:MCPeerID, position:Int) {
        
        print("New device", position, peerID.displayName)
        self.position = position
        self.peerID = peerID
        midiTimer = Timer.scheduledTimer(timeInterval: 1/15, target: self, selector: #selector(renderMIDI), userInfo: nil, repeats: true)
    }
    
    func update(position: Int) {
        print("Device \(peerID.displayName): updating position from \(self.position) to \(position)")
        self.position = position
        // Add any additional logic that needs to run when a device's position changes
    }
    
    //MARK: - EEG alpha
    var targetAlpha:Int = 0
    func process(alpha:Int) {
        
        //roughly multiply alpha in a midi range (0-127)
        let newAlphaForMIDI:Int = alpha * 15
        
        //if it's a new value, then record it
        if (newAlphaForMIDI != targetAlpha) {
            targetAlpha = newAlphaForMIDI
        }
    }
    
    //MARK: - MIDI
    var midiAlpha:Int = 0
    var midiInc:Int = 1
    @objc func renderMIDI() {
     
        var newMidi:Bool = false
        
        if targetAlpha > midiAlpha + midiInc {
            midiAlpha += 1
            newMidi = true
            
        } else if targetAlpha < midiAlpha - midiInc {
            midiAlpha -= 1
            newMidi = true
            
        } //else no change, and don't send midi
        
        if newMidi {
            if midiAlpha > 127 { midiAlpha = 127 } else if midiAlpha < 0 { midiAlpha = 0 }
            delegate?.didReceive(newAlphaCCValue: UInt8(midiAlpha), forChannel: UInt8(position-1))
        }
    }
}
