//
//  BpmProcessor.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/25/24.
//

import Foundation
import Combine

protocol BpmProcessorDelegate: AnyObject {
    func didDetect(newBpm: Int)
}

class BpmProcessor:ObservableObject {
    
    weak var delegate: BpmProcessorDelegate?
    
    private var bpmValues: [Int] = []
    @Published var averageBpm: Int = 0

    
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
                
                //update var
                averageBpm = newAverage
                
                //send to delegate
                self.delegate?.didDetect(newBpm: newAverage)
            }
        }
    }
}
