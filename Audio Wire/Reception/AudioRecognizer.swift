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
    let clockFreqencies = GlobalParameters.clockFreqencies
    let dataFreqencies = GlobalParameters.dataFreqencies
    let dataDelimiterFreqency = GlobalParameters.dataDelimiterFreqency
    
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
    var recognizedCharachter = ""
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
        var average = averageMagnitudes(onBands: dataFreqencies + clockFreqencies + [dataDelimiterFreqency], inArray: fftData)
    
        if currentClkHigh && average[16] > frequencyPresentThreshold && average[17] < frequencyPresentThreshold  {
            // print(average)
            average = average.dropLast(3)
            if let maxValue = average.max(), let index = average.firstIndex(of: maxValue) {
                var binaryRepresentation = String(index, radix: 2, uppercase: false)
                binaryRepresentation = String(repeating: "0", count: 4 - binaryRepresentation.count) + binaryRepresentation
                recognizedCharachter.append(binaryRepresentation)
                print(recognizedCharachter)
            }
            currentClkLow = true
            return
        }
        
        if currentClkLow && average[17] > frequencyPresentThreshold && average[16] < frequencyPresentThreshold{
            // print(average)
            average = average.dropLast(3)
            if let maxValue = average.max(), let index = average.firstIndex(of: maxValue) {
                var binaryRepresentation = String(index, radix: 2, uppercase: false)
                binaryRepresentation = String(repeating: "0", count: 4 - binaryRepresentation.count) + binaryRepresentation
                recognizedCharachter.append(binaryRepresentation)
                print(recognizedCharachter)
            }
            currentClkLow = false
            return
        }
        
        if recognizedCharachter.count == 16 {
            guard let integerRepresentation = UInt16(recognizedCharachter, radix: 2) else {
                print("can't treat \(recognizedCharachter) as binary and convert it to UInt")
                recognizedCharachter = ""
                return
            }
            guard let unicodeScalarRepresentation = UnicodeScalar(integerRepresentation) else {
                print("can't treat \(integerRepresentation) as char and convert it to UnicodeScalar")
                recognizedCharachter = ""
                return
            }
            let converted = Character(unicodeScalarRepresentation)
            print("successfully converted: \(recognizedCharachter) -> \(converted)")
            recognizerStream.append(converted)
            recognizedCharachter = ""
        }
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
