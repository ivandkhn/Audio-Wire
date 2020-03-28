//
//  TransmissionController.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 03.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import AudioKit

let gTransmissionController = TransmissionController()

class TransmissionController {
    
    // define frequencies
    let dataFreqencies = GlobalParameters.dataFreqencies.map { Float32($0) }
    let dataDelimiterFreqency = Float32(GlobalParameters.dataDelimiterFreqency)
    
    var packetLength = GlobalParameters.getSharedInstance().packetLength
    
    static func getSharedInstance() -> TransmissionController {
        return gTransmissionController
    }
    
    func send(message: String) {
        packetLength = GlobalParameters.getSharedInstance().packetLength
        AudioSynthesizer.sharedSynth().play(frequencies: [dataDelimiterFreqency], length: packetLength)
        let chunkedMessage = Array(message).chunked(into: 2)
        for chunk in chunkedMessage {
            var playedFrequencies: [Float] = []
            for symbolIndex in 0...1 {
                if chunk.count == 1 && symbolIndex == 1 {
                    // this means that the number of symbols in message
                    // is odd, so the last chunk has only one symbol.
                    // so we skip second one and proceed to playback
                    continue
                }
                let symbolBinaryRepresentation = Array(getBinaryRepresentation(ofChar: chunk[symbolIndex]))
                print("symbol \(chunk[symbolIndex]), binary \(symbolBinaryRepresentation):")
                let dataChunks = symbolBinaryRepresentation.chunked(into: 4)
                for (chunkIndex, chunk) in dataChunks.enumerated() {
                    let index = Int(String(chunk), radix: 2)
                    print("| append chunk \(chunk)")
                    guard let uIndex = index else {
                        print("index error!")
                        return
                    }
                    let indexWithOffcet = uIndex + chunkIndex*16 + symbolIndex*32
                    print("| uIdnex \(uIndex), w/offcet \(indexWithOffcet), so append freq \(dataFreqencies[indexWithOffcet])")
                    playedFrequencies.append(dataFreqencies[indexWithOffcet])
                }
            }
            print("└-> playing data: \(playedFrequencies)")
            AudioSynthesizer.sharedSynth().play(frequencies: playedFrequencies, length: packetLength)
        }
        AudioSynthesizer.sharedSynth().play(frequencies: [800], length: packetLength * 2)
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
