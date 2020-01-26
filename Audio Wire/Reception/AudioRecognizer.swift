//
//  AudioRecognizer.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 25.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import AudioKit

// The single instance.
let gAudioRecognizer: AudioRecognizer = AudioRecognizer()

class AudioRecognizer: ObservableObject {
    class func sharedRecognizer() -> AudioRecognizer {
        return gAudioRecognizer
    }
    
    var frequencyTracker = AKFrequencyTracker()
    @Published var isRunning = false
    var runningTimer = Timer()
    
    // wrap in @Published to tell SwiftUI to update
    // user interface when this variable changes
    @Published var recognizerStream = ""
    func startRecognition() {
        let mic = AKMicrophone()
        frequencyTracker = AKFrequencyTracker.init(mic)
        AKSettings.audioInputEnabled = true
        //let booster = AKBooster(mic, gain: 0)
        AudioKit.output = frequencyTracker
        do {
            try AudioKit.start()
        } catch {
            print("AudioEngine didn't start")
        }
        mic!.start()
        frequencyTracker.start()
        isRunning = true
        runningTimer = Timer.scheduledTimer(
            timeInterval: 0.05,
            target: self,
            selector: #selector(self.checkFrequency),
            userInfo: nil,
            repeats: true
        )
    }
    
    func stopRecognition() {
        runningTimer.invalidate()
        isRunning = false
        do {
            try AudioKit.stop()
        } catch {
            print("AudioEngine didn't stop!")
        }
    }
    
    @objc func checkFrequency() {
        print(frequencyTracker.frequency)
        print(recognizerStream)
        recognizerStream.append(getChar(forFrequency: Float32(frequencyTracker.frequency)))
    }
    
    func getChar(forFrequency frequency: Float32) -> Character {
        if (frequency < 440.0) {
            return "?"
        }
        return Character(UnicodeScalar(Int(frequency - 440.0) / 100) ?? "?")
    }
}
