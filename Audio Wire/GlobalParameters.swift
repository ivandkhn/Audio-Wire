//
//  GlobalParameters.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 08.02.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation

let gGlobal = GlobalParameters()

class GlobalParameters: ObservableObject {
    
    static func getSharedInstance() -> GlobalParameters {
        return gGlobal
    }
    
    // Sample rate for audio i/o
    static let sampleRate = 44100
    
    /* Future: 
     // Symbols delimiter
     static let dataDelimiterFreqency = 18863
     
     // Data frequencies definition
     static let dataFreqencies = [15719, 16149, 16537, 16925, 17312, 17700, 18087, 18475]
     
     // Clock frequencies definition
     static let clockFreqencies = [14900, 15288]
     */
    
    // Symbols delimiter
    static let dataDelimiterFreqency = 500
    
    // Data frequencies definition
    static let dataFreqencies = [1033, 1291, 1550, 1808, 2067, 2325, 2583, 2842, 3100, 3359, 3617, 3875, 4134, 4392, 4651, 4909, 5167, 5426, 5684, 5943, 6201, 6459, 6718, 6976, 7235, 7493, 7751, 8010, 8268, 8527, 8785, 9043, 9302, 9560, 9819, 10077, 10335, 10594, 10852, 11111, 11369, 11627, 11886, 12144, 12403, 12661, 12919, 13178, 13436, 13695, 13953, 14211, 14470, 14728, 14987, 15245, 15503, 15762, 16020, 16279, 16537, 16795, 17054, 17312]
    
    // Clock frequencies definition
    static let clockFreqencies = [8, 9].map{ $0 * 1000 }
    
    // How many bits we use to encode a single char
    static let binaryRepresentationLength = 8
    
    // Buffer size in samples
    static let samplesPerBuffer = 1024
    
    // Defines single transmission length, in buffers.
    @Published var packetLength = 5
    
    // Interval for timer that is listening for the input
    @Published var listeningTimerInterval = 0.01
    
    // The lower threshold that states that some frequency
    // exists after FFT is performed
    @Published var frequencyPresentThreshold = 0.0001
    
    // The amount of bands after FFT is performed
    // to calculate avegare magnitudes
    @Published var averageMagnitudesBandsCount = 3
    
}
