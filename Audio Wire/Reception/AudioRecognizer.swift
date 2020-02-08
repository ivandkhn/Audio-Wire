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
    
    // frequencies definition
    let clkLowFreq = 10000
    let clkHighFreq = 11000
    let dataLowFreq = 12000
    let dataHighFreq = 13000
    let dataDelimeterFreq = 14000
    
    // FFT variables
    var fftData = [Double]()
    let frequencyPresentThreshold = GlobalParameters.Reception.frequencyPresentThreshold
    let averageMargin = GlobalParameters.Reception.averageMagnitudesBandsCount
    
    // common audio parameters
    let sampleRate = GlobalParameters.sampleRate
    let sampleBufferSize = GlobalParameters.samplesPerBuffer
    
    // clock definitions
    var currentClkLow = false
    var currentClkHigh: Bool {
        get {
            return !currentClkLow
        }
        set(newValue) {
            return currentClkLow = !newValue
        }
    }
    
    // AK nodes
    var frequencyTracker = AKFrequencyTracker()
    var fftTap = AKFFTTap(AKNode())
    
    // wrap in @Published to tell SwiftUI to update
    // user interface when this variable changes
    @Published var isRunning = false
    @Published var recognizerStream = ""
    var runningTimer = Timer()
    
    func startRecognition() {
        let mic = AKMicrophone()
        frequencyTracker = AKFrequencyTracker.init(mic)
        if let unwrappedMic = mic {
            fftTap = AKFFTTap(unwrappedMic)
        }
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
            timeInterval: GlobalParameters.Reception.listeningTimerInterval,
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
        fftData = fftTap.fftData
        let average = averageMagnitudes(onBands: [clkLowFreq, clkHighFreq, dataLowFreq, dataHighFreq, dataDelimeterFreq], inArray: fftData)
    
        if currentClkHigh && average[0] > frequencyPresentThreshold && average[1] < frequencyPresentThreshold &&
            (average[2] > frequencyPresentThreshold || average[3] > frequencyPresentThreshold) {
            currentClkLow = true
            if average[2] > average[3] {
                print("receive 0, avg: \(average)")
            } else {
                print("receive 1, avg: \(average)")
            }
            return
        }
        if currentClkLow && average[1] > frequencyPresentThreshold && average[0] < frequencyPresentThreshold &&
            (average[2] > frequencyPresentThreshold || average[3] > frequencyPresentThreshold) {
            currentClkHigh = true
            if average[2] > average[3] {
                print("receive 0, avg: \(average)")
            } else {
                print("receive 1, avg: \(average)")
            }
            return
        }
        
        // recognizerStream.append(getChar(forFrequency: Float32(frequencyTracker.frequency)))
    }
    
    func getChar(forFrequency frequency: Float32) -> Character {
        if (frequency < 440.0) {
            return "?"
        }
        return Character(UnicodeScalar(Int(frequency - 440.0) / 100) ?? "?")
    }
    
    func argmax(_ ptr: UnsafePointer<Double>, count: Int, stride: Int = 1) -> (Int, Double) {
        var maxValue: Double = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxviD(ptr, vDSP_Stride(stride), &maxValue, &maxIndex, vDSP_Length(count))
        return (Int(maxIndex), maxValue)
    }
    
    func averageMagnitudes(onBands bands: [Int], inArray array: [Double]) -> [Double] {
        var result = [Double]()
        for bandFrequency in bands {
            let middle = Int(bandFrequency * sampleBufferSize / sampleRate)
            var sum = 0.0
            for offcet in 0..<averageMargin {
                sum += array[middle - Int(averageMargin / 2) + offcet]
            }
            result.append(sum)
        }
        
        return result
    }
}
