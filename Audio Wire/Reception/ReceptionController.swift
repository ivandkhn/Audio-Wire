//
//  ReceptionController.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 27.02.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation

enum DataTypes {
    case String
    case Audio // not implemented
    case Image // not implemented
}

class ReceptionController: ObservableObject {
    
    @Published var receivedStream = ""
    @Published var isRunning = false
    
    func startStreamRecognition() {
        
        // TOOD
        
        isRunning = true
    }
    
    func stopStreamRecognition() {
        
        // TOOD
        
        isRunning = false
    }
    
    func received(binaryData: String, convertTo dataType: DataTypes) -> Character? {
        if (dataType == .String) {
            guard let integerRepresentation = UInt16(binaryData, radix: 2) else {
                print("can't treat \(binaryData) as binary and convert it to UInt")
                return nil
            }
            guard let unicodeScalarRepresentation = UnicodeScalar(integerRepresentation) else {
                print("can't treat \(integerRepresentation) as char and convert it to UnicodeScalar")
                return nil
            }
            let converted = Character(unicodeScalarRepresentation)
            print("successfully converted: \(binaryData) -> \(converted)")
            return converted
        }
        
        return nil // other data types not implemented yet!
    }
    
}
