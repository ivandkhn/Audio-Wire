//
//  ReceivedMessage.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 26.03.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import Foundation


struct ReceivedMessage: Hashable {
    var content: String
    var customParameter: Double
}

let gReceivedMessagePool = ReceivedMessagePool()

class ReceivedMessagePool: ObservableObject {
    @Published var messages: [ReceivedMessage] = []
    
    class func sharedInstance() -> ReceivedMessagePool {
        return gReceivedMessagePool
    }
    
    func createNewMessage() {
        messages.append(ReceivedMessage(content: "", customParameter: 0))
    }
    
    func update(newText: String) {
        messages[messages.count-1].content = newText
    }
    
    func removeAll() {
        messages.removeAll()
    }
}
