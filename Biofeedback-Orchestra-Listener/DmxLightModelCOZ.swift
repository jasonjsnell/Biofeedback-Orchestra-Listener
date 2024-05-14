//
//  TheaterDMXLight.swift
//  EEG-OSX
//
//  Created by Jason Snell on 10/6/22.
//

import Foundation
import XvMidi

class DmxLightModelCOZ {
    
    //DMX decabox
    //ch 0 = 1-63 overall brightness
    //ch 1, 2, 3 = 1-127 brightness of R G B
    //init every 4th channel to max brightness of 63. This is unique to my home DMX lights
    
    public static let MIDI_TO_DMX_CHANNEL:UInt8 = 14
    
    fileprivate let midi:XvMidi
    fileprivate let chFunction:UInt8
    fileprivate let chR:UInt8
    fileprivate let chG:UInt8
    fileprivate let chB:UInt8
    
    init(startingAddress:UInt8) {
        
        chFunction = startingAddress-1
        chR = startingAddress
        chG = startingAddress + 1
        chB = startingAddress + 2
        
        midi = XvMidi.sharedInstance
    }
    
    func set(r:UInt8, g:UInt8, b:UInt8) {
        
        //print("RGB", r, g, b)
        midi.noteOn(channel: DmxLightModelCOZ.MIDI_TO_DMX_CHANNEL, note: chFunction, velocity: 63)//full bright
        midi.noteOn(channel: DmxLightModelCOZ.MIDI_TO_DMX_CHANNEL, note: chR, velocity: r) //red brightness
        midi.noteOn(channel: DmxLightModelCOZ.MIDI_TO_DMX_CHANNEL, note: chG, velocity: g) //greeen bright
        midi.noteOn(channel: DmxLightModelCOZ.MIDI_TO_DMX_CHANNEL, note: chB, velocity: b) //blue bright
        
    }
    
    
    
}


