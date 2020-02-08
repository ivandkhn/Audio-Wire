//
//  GlobalParameters.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 08.02.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation

struct GlobalParameters {
    // Sample rate for audio i/o
    static let sampleRate = 44100
    
    // Data frequencies definition
    static let dataFreqencies = [10, 11, 12, 13, 14, 15, 16, 17].map{ $0 * 1000 }
    
    // Clock frequencies definition
    static let clockFreqencies = [8, 9].map{ $0 * 1000 }
    
    // How many bits we use to encode a single char
    static let binaryRepresentationLength = 16
    
    // Buffer size in samples
    static let samplesPerBuffer = 1024
    
    struct Transmission {
        // Defines single transmission length, in buffers.
        static let packetLength = 5
    }
    
    struct Reception {
        // Interval for timer that is listening for the input
        static let listeningTimerInterval = 0.001
        
        // The lower threshold that states that some frequency
        // exists after FFT is performed
        static let frequencyPresentThreshold = 0.0001
        
        // The amount of bands after FFT is performed
        // to calculate avegare magnitudes
        static let averageMagnitudesBandsCount = 5
    }
    
}
