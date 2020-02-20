//
//  TransmissionController.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 03.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import AudioKit

// test string:
// !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~

class TransmissionController {
    
    // define frequencies
    let clockFreqencies = GlobalParameters.clockFreqencies.map { Float32($0) }
    let dataFreqencies = GlobalParameters.dataFreqencies.map { Float32($0) }
    let dataDelimiterFreqency = Float32(GlobalParameters.dataDelimiterFreqency)
    
    let packetLength = GlobalParameters.Transmission.packetLength
    
    // current clock state
    var clkLow = true
    
    func send(message: String) {
        for symbol in message {
            AudioSynthesizer.sharedSynth().play(frequencies: [dataDelimiterFreqency], length: packetLength)
            clkLow = true
            let symbolBinaryRepresentation = Array(getBinaryRepresentation(ofChar: symbol))
            let dataChunks = symbolBinaryRepresentation.chunked(into: 4)
            for chunk in dataChunks {
                let index = Int(String(chunk), radix: 2)
                var playedFrequencies: [Float] = []
                playedFrequencies.append(clkLow ? clockFreqencies[0] : clockFreqencies[1])
                playedFrequencies.append(dataFreqencies[index!])
                AudioSynthesizer.sharedSynth().play(frequencies: playedFrequencies, length: packetLength)
                clkLow.toggle()
            }
        }
    }
    
    func getBinaryRepresentation(ofChar char: Character) -> String {
        
        let integerRepresentation: UInt16 = String(char).utf16.map{UInt16($0)}[0]
        let binaryRepresentation = String(integerRepresentation, radix: 2, uppercase: false)
        let paddedBinaryRepresentation = String(
            repeating: "0",
            count: GlobalParameters.binaryRepresentationLength - binaryRepresentation.count
        ) + binaryRepresentation
        return paddedBinaryRepresentation
    }
    
    func getFrequency(forChar char: Character) -> Float32{
        return Float32(440.0 + 100.0 * Float32(char.asciiValue!))
    }
    
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
