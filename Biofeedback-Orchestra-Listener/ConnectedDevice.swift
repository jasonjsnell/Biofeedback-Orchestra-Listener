//
//  MusicianPeer.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/24/24.
//

import Foundation
import MultipeerConnectivity
//import XvMidi

protocol ConnectedDeviceDelegate: AnyObject {
    func didreceive(newAlphaNoteOn: UInt8, atVelocity:UInt8, forChannel: UInt8)
    func didreceive(newAlphaNoteOff: UInt8, forChannel: UInt8)
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
        midiTimer = Timer.scheduledTimer(timeInterval: 1/15, target: self, selector: #selector(renderMIDICC), userInfo: nil, repeats: true)
    }
    
    func update(position: Int) {
        print("Device \(peerID.displayName): updating position from \(self.position) to \(position)")
        self.position = position
        // Add any additional logic that needs to run when a device's position changes
    }
    
    //MARK: - EEG alpha
    var targetAlpha:Int = 0
    func process(alphaCC:Int) {
        
        //if it's a new value, then record it
        if (alphaCC != targetAlpha) {
            targetAlpha = alphaCC
        }
    }
    
    func canConvertToInt8(value: Int) -> Bool {
        return value >= 0 && value < 128
    }
    
    func processAlphaNote(on:Bool, note:Int, velocity: Int){
        
        if !canConvertToInt8(value: note) {
            print("Note", note, "is not within UInt8 range")
            return
        }
        if !canConvertToInt8(value: velocity) {
            print("Velocity", note, "is not within UInt8 range")
            return
        }
        
        if (on){
        print("Note ON | Ch:", position-1, "Velo:", velocity)
            //note on
            delegate?.didreceive(
                newAlphaNoteOn: UInt8(note),
                atVelocity: UInt8(velocity),
                forChannel: UInt8(position-1)
            )
        } else if (!on) {
            print("Note OFF | Ch:", position-1)
            //note off
            delegate?.didreceive(
                newAlphaNoteOff: UInt8(note),
                forChannel: UInt8(position-1)
            )
        }
        
    }
    
    //MARK: - MIDI
    var midiAlpha:Int = 0
    var midiInc:Int = 1
    @objc func renderMIDICC() {
     
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
