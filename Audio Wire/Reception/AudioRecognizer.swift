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

class AudioRecognizer {
    class func sharedRecognizer() -> AudioRecognizer {
        return gAudioRecognizer
    }
    
    var frequencyTracker = AKFrequencyTracker()
    var recognizerStream = ""
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
        let t = Timer.scheduledTimer( timeInterval: 0.05, target: self, selector: #selector(self.checkFrequency), userInfo: nil, repeats: true)

    }
    
    @objc func checkFrequency() {
        print(frequencyTracker.frequency)
        print(recognizerStream)
        recognizerStream.append(getChar(forFrequency: Float32(frequencyTracker.frequency)))
    }
    
//    func getFrequency(forChar char: Character) -> Float32{
//        return Float32(440.0 + 100.0 * Float32(char.asciiValue!))
//    }
    
    func getChar(forFrequency frequency: Float32) -> Character {
        if (frequency < 440.0) {
            return "?"
        }
        return Character(UnicodeScalar(Int(frequency - 440.0) / 100) ?? "?")
    }
}
