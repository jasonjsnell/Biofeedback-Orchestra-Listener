//this is the class where data from Muse devices via the phones / iPads comes into the laptop
//Muse -> iPhone -> this laptop

import MultipeerConnectivity
import XvMidi

class MultipeerSessionManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
 
    
    // MARK: - Properties
    private let serviceType = "eeg-network"
    private let myPeerId: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var midi:XvMidi
    private let MIDI_ALPHA_CC:UInt8 = 20
    
    
    //connected devices
    @Published var connectedDevices: [ConnectedDevice] = []
    @Published var midiSlots: [MIDISlot] = Array(
        repeating: MIDISlot(
            id: 0,
            device: nil
        ),
        count: 10
    )
    
    //processors
    @Published var bpmProcessor:BpmProcessor = BpmProcessor()
    
    //packets per second
    private var packetCount = 0
    private var lastPacketTimestamp = Date()
    
    //
       
    // MARK: - Initializer
    override init() {
        self.myPeerId = MCPeerID(displayName: "EEG Laptop")
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
               
        midi = XvMidi.sharedInstance
        let midiSuccess:Bool = midi.initMidi(withAppID: "Biofeedback-Orchestra")
        if (midiSuccess) { print("XvMidi: Init") }
        
        super.init()
        
        //delegates
        self.session.delegate = self
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
        
        // Initialize the slots with unique IDs
        for index in 0..<midiSlots.count { midiSlots[index].id = index + 1 }
        
    }
    
    // MARK: - Advertiser Delegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations from clients
        invitationHandler(true, self.session)
    }

    //MARK: Connection
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .connected:
                print("EEG Laptop: Connected: \(peerID.displayName)")
                // Add the connected peer to the list
                addDevice(peerID: peerID)

            case .notConnected:
                print("EEG Laptop: Not Connected: \(peerID.displayName)")
                // Remove the disconnected peer from the list
                removeDevice(peerID: peerID)

            case .connecting:
                print("EEG Laptop: Connecting: \(peerID.displayName)")

            default:
                break
            }
        }
    }

    
    //MARK: - add / remove devices
    private func addDevice(peerID: MCPeerID) {
        let newDevice = ConnectedDevice(peerID: peerID, position: findAvailableSlot())

        if let slotIndex = midiSlots.firstIndex(where: { $0.id == newDevice.position }) {
            DispatchQueue.main.async {
                self.midiSlots[slotIndex].device = newDevice
            }
        }
        newDevice.delegate = self
        connectedDevices.append(newDevice)
    }
    
    private func removeDevice(peerID: MCPeerID) {
        // Remove the device from the connected devices array
        if let deviceIndex = connectedDevices.firstIndex(where: { $0.peerID == peerID }) {
            connectedDevices.remove(at: deviceIndex)
        }

        // Find the corresponding slot and nil out the device
        if let slotIndex = midiSlots.firstIndex(where: { $0.device?.peerID == peerID }) {
            DispatchQueue.main.async {
                self.midiSlots[slotIndex].device = nil
            }
        }
    }
    
    private func findAvailableSlot() -> Int {
        // Find the first slot that does not contain a device and return its ID
        return midiSlots.first(where: { $0.device == nil })?.id ?? 1
    }

    //MARK: data coming in from iphones via airdrop
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            
            print("RX from", peerID.displayName)
            if let dataDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let type = dataDict["type"] as? String {
                
                //calculatePacketsPerSecond()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // Check if the deviceID already exists in the connectedDevices array
                    if let connectedDevice = self.connectedDevices.first(where: { $0.peerID == peerID }) {
                        // Process the received data based on its type
                        self.processData(
                            type: type,
                            dataDict: dataDict,
                            connectedDevice: connectedDevice
                        )
                    } else {
                        // Device doesn't exist, so handle the new device
                        self.addDevice(peerID: peerID)
                        // If this was not a "hello" message, process the data immediately
                        if let connectedDevice = self.connectedDevices.last {
                            self.processData(
                                type: type,
                                dataDict: dataDict,
                                connectedDevice: connectedDevice
                            )
                        }
                    }
                }
            }
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
        }
    }
    
    private func processData(type: String, dataDict: [String: Any], connectedDevice: ConnectedDevice) {
        // This function is used to process "eeg" and "heart" messages for an existing connected device
        switch type {
        case "alphaCC":
           
            if let alphaCC:Int = dataDict["value"] as? Int {
                // Process EEG data for the specific ConnectedDevice object
                connectedDevice.process(alphaCC: alphaCC)
            }
        case "alphaNote":
           
            if let on:Bool = dataDict["on"] as? Bool,
               let note:Int = dataDict["note"] as? Int,
               let velocity:Int = dataDict["velocity"] as? Int {
                
                // Process EEG data for the specific ConnectedDevice object
                connectedDevice.processAlphaNote(on: on, note:note, velocity: velocity)
            }
        case "heart":
            if let bpm:Int = dataDict["bpm"] as? Int, 
                let hrv:Int = dataDict["hrv"] as? Int {
                // Pass bpm to processor to detect group average
                bpmProcessor.add(bpm: bpm)
            }
        default:
            print("Data type \(type) received for device \(connectedDevice.peerID)")
        }
    }
    
    private func calculatePacketsPerSecond(){
        // Increment the packet count
        packetCount += 1
        
        // Calculate the packets per second
        let currentTimestamp = Date()
        let elapsedTime = currentTimestamp.timeIntervalSince(lastPacketTimestamp)
        
        if elapsedTime >= 1.0 {
            // Update the packetsPerSecond variable
            let packetsPerSecond = Int(Double(packetCount) / elapsedTime)
            
            // Reset the packet count and last timestamp
            packetCount = 0
            lastPacketTimestamp = currentTimestamp
            
            print("Packets per second: \(packetsPerSecond)")
        }
    }

    //MARK: Unused session funcs
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    //MIDI mapping
    func sendAlphaMidiPulse(toChannel:Int) {
        let randomValue: UInt8 = UInt8.random(in: 0...UInt8.max)
        midi.controlChange(channel: UInt8(toChannel), controller: MIDI_ALPHA_CC, value: randomValue)
    }
}

//MARK: - Send to MIDI

extension MultipeerSessionManager: ConnectedDeviceDelegate {
    
    
    func didreceive(newAlphaNoteOn: UInt8, atVelocity: UInt8, forChannel: UInt8) {
        midi.noteOn(channel: forChannel, note: newAlphaNoteOn, velocity: atVelocity)
    }
    
    func didreceive(newAlphaNoteOff: UInt8, forChannel: UInt8) {
        midi.noteOff(channel: forChannel, note: newAlphaNoteOff)
    }
    
    func didReceive(newAlphaCCValue: UInt8, forChannel: UInt8) {
        midi.controlChange(channel: forChannel, controller: MIDI_ALPHA_CC, value: newAlphaCCValue)
    }
}
