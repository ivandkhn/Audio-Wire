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
    
    // frequencies definition
    let dataFreqencies = GlobalParameters.dataFreqencies
    let dataDelimiterFreqency = GlobalParameters.dataDelimiterFreqency
    
    // FFT variables
    var fftData = [Double]()
    let frequencyPresentThreshold = 0.001
    let averageMargin = GlobalParameters.getSharedInstance().averageMagnitudesBandsCount
    
    // common audio parameters
    let sampleRate = GlobalParameters.sampleRate
    let sampleBufferSize = GlobalParameters.samplesPerBuffer
    var packetLength = GlobalParameters.getSharedInstance().packetLength
    var dataChunkDuration: Double {
        return packetLength * GlobalParameters.samplesPerBuffer / GlobalParameters.sampleRate
    }
    
    // AK nodes
    var frequencyTracker = AKFrequencyTracker()
    var fftTap = AKFFTTap(AKNode())
    var mic = AKMicrophone()
    
    var receptionController = ReceptionController.sharedInstance()
    
    var isRunning = false
    var transmissionStartListener = Timer()
    var dataChunkListener = Timer()
    
    func startTransmissionListener() {
        mic = AKMicrophone()
        frequencyTracker = AKFrequencyTracker.init(mic)
        if let unwrappedMic = mic {
            fftTap = AKFFTTap(unwrappedMic)
        }
        AKSettings.audioInputEnabled = true
        
        // mute mic input
        let mixer = AKMixer(mic)
        mixer.volume = 0
        AudioKit.output = mixer
        
        do {
            try AudioKit.start()
        } catch {
            print("AudioEngine didn't start")
        }
        mic!.start()
        frequencyTracker.start()
        isRunning = true
        transmissionStartListener = Timer.scheduledTimer(
            timeInterval: GlobalParameters.getSharedInstance().listeningTimerInterval,
            target: self,
            selector: #selector(self.checkTransmissionStartMarker),
            userInfo: nil,
            repeats: true
        )
        print("listening for transmission start marker...")
    }
    
    func stopTransmissionListener() {
        print("listener engine is stopped")
        transmissionStartListener.invalidate()
        dataChunkListener.invalidate()
        do {
            frequencyTracker.detach()
            AudioKit.disconnectAllInputs()
            try AudioKit.stop()
            isRunning = false
        } catch {
            print("AudioEngine didn't stop!")
        }
    }
    
    @objc func checkTransmissionStartMarker() {
        fftData = fftTap.fftData
        let average = averageMagnitudes(onBands: [dataDelimiterFreqency], inArray: fftData)
        if average[0] > frequencyPresentThreshold {
            print("detected start marker with amplitude \(average[0])")
            packetLength = GlobalParameters.getSharedInstance().packetLength
            transmissionStartListener.invalidate()
            receptionController.onDataDelimeterReceived()
            Timer.scheduledTimer(withTimeInterval: dataChunkDuration / 2,
                                 repeats: false,
                                 block: { timer in self.startDataChunkListener() })
        }
    }
    
    @objc func startDataChunkListener() {
        dataChunkListener = Timer.scheduledTimer(
            timeInterval: dataChunkDuration,
            target: self,
            selector: #selector(self.receiveDataChunk),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func receiveDataChunk() {
        fftData = fftTap.fftData
        let delimeterAverage = averageMagnitudes(onBands: [800], inArray: fftData)
        if delimeterAverage[0] > frequencyPresentThreshold * 0.8 {
            print("detected end marker with amplitude \(delimeterAverage[0])")
            dataChunkListener.invalidate()
            transmissionStartListener = Timer.scheduledTimer(
                timeInterval: GlobalParameters.getSharedInstance().listeningTimerInterval,
                target: self,
                selector: #selector(self.checkTransmissionStartMarker),
                userInfo: nil,
                repeats: true
            )
            print("listening for transmission start marker...")
            return
        }
        print("receiving chunk...")
        receptionController.onDataReceived(fftData: fftData)
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
