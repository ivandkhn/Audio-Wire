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
    func send(message: String) {
        for i in message {
            NSLog("Symbol \(i) / frequency \(getFrequency(forChar: i))")
            AudioSynthesizer.sharedSynth().play(getFrequency(forChar: i), modulatorFrequency: 679.0, modulatorAmplitude: 0, length: 7)
        }
    }
    
    func getFrequency(forChar char: Character) -> Float32{
        return Float32(440.0 + 100.0 * Float32(char.asciiValue!))
    }
    
}
