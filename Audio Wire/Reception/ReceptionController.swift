//
//  ReceptionController.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 27.02.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import Accelerate

enum DataTypes {
    case String
    case Audio // not implemented
    case Image // not implemented
}

let gReceptionController = ReceptionController()

class ReceptionController: ObservableObject {
    
    @Published var receivedStream = ""
    @Published var isRunning = false
    
    enum DataRepresentation {
        case bits8
        case bits16
    }
    var currentDataRepresentation: DataRepresentation = .bits8
    
    var messagePool = ReceivedMessagePool.sharedInstance()
    
    var recognizerStream = ""
    
    class func sharedInstance() -> ReceptionController {
        return gReceptionController
    }
    
    func startStreamRecognition() {
        AudioRecognizer.sharedRecognizer().startTransmissionListener()
        isRunning = true
    }
    
    func stopStreamRecognition() {
        AudioRecognizer.sharedRecognizer().stopTransmissionListener()
        isRunning = false
    }
    
    func onDataDelimeterReceived() {
        messagePool.createNewMessage()
        recognizerStream = ""
    }
    
    func onDataReceived(fftData: [Double]) {
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
            messagePool.update(newText: recognizerStream)
        }
    }
    
    func decodeSymbol(fromBinary binary: String) -> Character? {
        guard let integerRepresentation = UInt16(binary, radix: 2) else {
            print("can't treat \(binary) as binary and convert it to UInt")
            return nil
        }
        guard let unicodeScalarRepresentation = UnicodeScalar(integerRepresentation) else {
            print("can't treat \(integerRepresentation) as char and convert it to UnicodeScalar")
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
    
}
