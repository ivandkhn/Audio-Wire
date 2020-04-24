//
//  ContentView.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 03.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    // send or receive tab
    @State var selectedView = 0
    
    // message in the input box
    @State var message = ""
    
    //
    @State var transmissionController = TransmissionController.getSharedInstance()
    
    // show settings modal view
    @State private var showModal = false
    
    // some vars to track changes in reception states
    @ObservedObject var messagesPool = ReceivedMessagePool.sharedInstance()
    @ObservedObject var receptionController = ReceptionController.sharedInstance()
        
    var body: some View {
        TabView(selection: $selectedView) {
            // =============== Tab 1 : send ===============
            VStack {
                TextField("Message", text: $message).padding()
                
                HStack {
                    Image(systemName: "radiowaves.right").onTapGesture {
                        self.transmissionController.send(message: self.message)
                        self.message = ""
                    }.font(.title)
                    Spacer()
                    Image(systemName: "slider.horizontal.3").font(.title).onTapGesture {
                        self.showModal.toggle()
                    }.font(.title)
                }.padding()
                
            }
            .padding()
            .tabItem {
                Image(systemName: "radiowaves.right")
                Text("Send")
            }
            .tag(0)
            
            // =============== Tab 2 : receive ===============
            VStack {
                List {
                    ForEach(messagesPool.messages, id: \.self) { msg in
                        VStack(alignment: .leading) {
                            Text(msg.content)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: self.receptionController.isRunning ? "stop" : "play").onTapGesture {
                        self.receptionController.isRunning ? self.receptionController.stopStreamRecognition() : self.receptionController.startStreamRecognition()
                    }.font(.title)
                    
                    Spacer()
                    Button(action: { self.messagesPool.removeAll() },
                           label: {Text("Remove all")}
                    )
                    
                    Spacer()
                    Image(systemName: "slider.horizontal.3").font(.title).onTapGesture {
                        self.showModal.toggle()
                    }
                }.padding()
                
            }
            .padding()
            .tabItem {
                Image(systemName: "radiowaves.left")
                Text("Receive")
            }
            .tag(1)
        }
        .sheet(isPresented: $showModal) {
            SettingsModalView(showModal: self.$showModal)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(selectedView: 0).environment(\.colorScheme, .dark)
            ContentView(selectedView: 1).environment(\.colorScheme, .dark)
            SettingsModalView(showModal: .constant(true)).environment(\.colorScheme, .dark)
        }
    }
}
