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
    
    enum DataRepresentation {
        case bits8
        case bits16
    }
    var currentDataRepresentation: DataRepresentation = .bits8
    
    class func sharedRecognizer() -> AudioRecognizer {
        return gAudioRecognizer
    }
    
    // frequencies definition
    let clockFreqencies = GlobalParameters.clockFreqencies
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
    var transmissionStartListener = Timer()
    var dataChunkListener = Timer()
    
    func startTransmissionListener(newPacketLength: Int) {
        packetLength = newPacketLength
        let mic = AKMicrophone()
        frequencyTracker = AKFrequencyTracker.init(mic)
        if let unwrappedMic = mic {
            fftTap = AKFFTTap(unwrappedMic)
        }
        AKSettings.audioInputEnabled = true
        //let booster = AKBooster(mic, gain: 0)
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
        currentDataRepresentation = .bits8
        print("listening for transmission start marker...")
    }
    
    func stopTransmissionListener() {
        print("listener engine is stopped")
        transmissionStartListener.invalidate()
        dataChunkListener.invalidate()
        do {
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
            Timer.scheduledTimer(withTimeInterval: dataChunkDuration / 2,
                                 repeats: false,
                                 block: {timer in self.startDataChunkListener()})
            
        } else {
            return
        }
    }
    
    @objc func startDataChunkListener() {
        dataChunkListener = Timer.scheduledTimer(
            //timeInterval: 0.2321, // buffersPerChunk * samplesPerBuffer / sampleRate
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
        // start with 24th fft data
        // next is 30
        var analyzeData = fftData
        analyzeData = analyzeData.enumerated().compactMap { index, element in
            (index >= 24 && index <= 402 && index % 6 == 0) ? element : nil
        }

        let chunkedAnalyzeData = analyzeData.chunked(into: 16)
        var decodedBinary = ""
        for chunk in chunkedAnalyzeData {
            let max = argmax(chunk, count: chunk.count)
            var binaryRepresentation = String(max.0, radix: 2)
            binaryRepresentation = String(repeating: "0", count: 4 - binaryRepresentation.count) + binaryRepresentation
            decodedBinary.append(binaryRepresentation)
        }
        var chars: [String] = []
        switch currentDataRepresentation {
        case .bits8:
            chars = [String(decodedBinary.dropLast(8)), String(decodedBinary.dropFirst(8))]
        case .bits16:
            chars = [decodedBinary]
        }
        for char in chars {
            if let decodedSymbol = decodeSymbol(fromBinary: char) {
                recognizerStream.append(decodedSymbol)
            } else {
                recognizerStream.append("?")
            }
        }
        
    }
    
    func decodeSymbol(fromBinary binary: String) -> Character? {
        guard let integerRepresentation = UInt16(binary, radix: 2) else {
            print("can't treat \(binary) as binary and convert it to UInt")
            return nil
        }
        guard let unicodeScalarRepresentation = UnicodeScalar(integerRepresentation) else {
            print("can't treat \(integerRepresentation) as char and convert it to UnicodeScalar")
            recognizedCharachter = ""
            return nil
        }
        return Character(unicodeScalarRepresentation)
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
