import MultipeerConnectivity

class MultipeerSessionManager: NSObject, ObservableObject {
    // MARK: - Properties
    private let serviceType = "eeg-network"
    private let myPeerId: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    
    @Published var connectedPeers: [MCPeerID] = []
       
    // MARK: - Initializer
    override init() {
        self.myPeerId = MCPeerID(displayName: "EEG Laptop")
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.advertiser.delegate = self
    }
    
    // MARK: - Methods for Advertising
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }

    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
    }

}

// MARK: - MCSessionDelegate
extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("session didChange", state)
        
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                print("Connected: \(peerID.displayName)")
                self?.connectedPeers.append(peerID)
            case .notConnected:
                print("Not Connected: \(peerID.displayName)")
                if let index = self?.connectedPeers.firstIndex(of: peerID) {
                    self?.connectedPeers.remove(at: index)
                }
            case .connecting:
                print("Connecting: \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let dataDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let type = dataDict["type"] as? String {
                
                DispatchQueue.main.async {
                    
                    print("RX: \(type) ")
                    
                    switch type {
                    case "eeg":
                        
                        if let brainwaves = dataDict["brainwaves"] as? [Int], let deviceID = dataDict["deviceID"] as? String {
                            print("Received EEG data from \(deviceID): \(brainwaves)")
                            // Process EEG data here
                        }
                    case "heart":
                        if let bpm = dataDict["bpm"] as? Int, let hrv = dataDict["hrv"] as? Int, let deviceID = dataDict["deviceID"] as? String {
                            print("Received Heart data from \(deviceID): BPM: \(bpm), HRV: \(hrv)")
                            // Process Heart Rate data here
                        }
                    default:
                        print("Unknown data type received")
                    }
                }
                
            
                    
                
            }
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Streams are not used in this example
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Resource transfer not used in this example
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Resource transfer not used in this example
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations
        invitationHandler(true, session)
    }
}
