//
//  BpmProcessor.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/25/24.
//

import UIKit
import XvAbletonLink
import XvTimer

class BpmProcessor:ObservableObject {
    
    private var link:XvAbletonLink
    private var timer:XvTimer
    
    private var bpmValues: [Int] = []
    @Published var averageBpm: Int = 0

    init(){
        timer = XvTimer.sharedInstance
        link = XvAbletonLink.sharedInstance
        
        print("init BPM with timer")
        timer.initTimer(withAppID: "Biofeedback-Orchestra")
        timer.audioClockOn = true
        timer.delegate = self
        print("timer", timer)
        
        link.setup(bpm: 60, quantum: 16.0)
        link.set(active: true)
        link.start()
    }
    
    func getABLinkViewController() -> UIViewController? {
        
        if let vc:UIViewController = link.getViewController() {
            print("Retriving ABLink VC from Link framework", vc)
            vc.view.backgroundColor = UIColor.white
            return vc
        } else {
            print("Error: Invalid view controler from ABLLink")
            return nil
        }
    }
    
    func add(bpm:Int){
        // Add the new BPM to the array
        bpmValues.append(bpm)
        
        // If the array exceeds 50 items, remove the oldest
        if bpmValues.count > 50 {
            bpmValues.removeFirst()
        }
        
        // Recalculate the average
        updateAverage()
    }
    
    private func updateAverage() {
        let sum = bpmValues.reduce(0, +)
        DispatchQueue.main.async { [self] in
            
            let newAverage = Int(Double(sum) / Double(bpmValues.count))
            
            //only publish new results
            if (newAverage != averageBpm) {
                print("Updated Average BPM: \(averageBpm)")
                
                //update var for GUI
                averageBpm = newAverage
                
                //send new BPM to Ableton and other peers
                link.bpm = Float64(newAverage)
            }
        }
    }
}

extension BpmProcessor: XvTimerDelegate {
    func audioClockTick() {
        link.audioClock()
    }
    
    func guiTimerTick() {}

}
