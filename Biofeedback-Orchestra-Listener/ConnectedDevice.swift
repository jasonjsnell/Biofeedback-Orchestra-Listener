//
//  MusicianPeer.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/24/24.
//

import Foundation
import MultipeerConnectivity

protocol ConnectedDeviceDelegate: AnyObject {
    func didDetect(newAlphaNote: Int, forDevice deviceID: String)
}

class ConnectedDevice:Identifiable {
    
    weak var delegate: ConnectedDeviceDelegate?
    var peerID: MCPeerID
    var position:Int
    
    init(peerID:MCPeerID, position:Int) {
        print("New device", position, peerID.displayName)
        self.position = position
        self.peerID = peerID
    }
    
    func process(brainwaves:[Int]) {
        //print("brainwaves", brainwaves)
        
        //delegate?.didDetect(newAlphaNote: alphaNote, forDevice: deviceID)
    }
}
