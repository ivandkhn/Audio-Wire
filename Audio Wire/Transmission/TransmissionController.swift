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
    let clkLowFreq: Float32 = 10000
    let clkHighFreq: Float32 = 11000
    let dataLowFreq: Float32 = 12000
    let dataHighFreq: Float32 = 13000
    let dataDelimeterFreq: Float32 = 14000
    
    let framesPerSymbol = 5
    
    // current clock state
    var clkLow = true
    
    func send(message: String) {
        for symbol in message {
            AudioSynthesizer.sharedSynth().play(firstFrequency: dataDelimeterFreq,
                                                secondFrequency: 0,
                                                secondFrequencyAmplitude: 0,
                                                length: GlobalParameters.Transmission.packetLength
            )
            clkLow = true
            for ch in getBinaryRepresentation(ofChar: symbol) {
                AudioSynthesizer.sharedSynth().play(firstFrequency: ch == "0" ? dataLowFreq : dataHighFreq,
                                                    secondFrequency: clkLow ? clkLowFreq : clkHighFreq,
                                                    secondFrequencyAmplitude: 1,
                                                    length: GlobalParameters.Transmission.packetLength
                )
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
        )
        return paddedBinaryRepresentation
        // convert back: let char = Character( UnicodeScalar(paddedBinaryRepresentation)! )
    }
    
    func getFrequency(forChar char: Character) -> Float32{
        return Float32(440.0 + 100.0 * Float32(char.asciiValue!))
    }
    
}
