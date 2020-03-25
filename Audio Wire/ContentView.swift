//
//  ContentView.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 03.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    let avaliablePacketLength = 1...20
    
    @State var selectedView = 0
    @State var selectedPacketLength: Int = GlobalParameters.getSharedInstance().packetLength
    @State var message = ""
    @State var transmissionController = TransmissionController.getSharedInstance()
    @State private var showModal = false
    
    // wrap in @ObservedObject to catch inner property changes
    @ObservedObject var AR = AudioRecognizer.sharedRecognizer()
    @ObservedObject var globals = GlobalParameters.getSharedInstance()
        
    var body: some View {
        TabView(selection: $selectedView) {
            // =============== Tab 1 : send ===============
            VStack {
                HStack {
                    //TextField(text: $message)
                    TextField("Message", text: $message)
                    Image(systemName: "radiowaves.right").onTapGesture {
                        self.globals.packetLength = self.selectedPacketLength
                        self.transmissionController.send(message: self.message)
                        self.message = ""
                    }.font(.title)
                }
                Stepper(value: $selectedPacketLength,
                        in: avaliablePacketLength,
                        onEditingChanged: { _ in
                            self.globals.packetLength = self.selectedPacketLength
                        },
                        label: { Text("Packet length: \(selectedPacketLength)")}
                )
                Image(systemName: "slider.horizontal.3").font(.title).onTapGesture {
                    self.showModal.toggle()
                }
            }
            .padding()
            .tabItem {
                Image(systemName: "radiowaves.right")
                Text("Send")
            }
            .tag(0)
            
            // =============== Tab 2 : receive ===============
            VStack {
                Button(action: {
                    self.AR.isRunning ? self.AR.stopTransmissionListener() : self.AR.startTransmissionListener(newPacketLength: self.selectedPacketLength)
                }) {
                    Text(AR.isRunning ? "Stop" : "Start audio engine")
                        .font(.headline)
                }
                Stepper(value: $selectedPacketLength,
                        in: avaliablePacketLength,
                        onEditingChanged: { _ in
                            self.globals.packetLength = self.selectedPacketLength
                        },
                        label: { Text("Packet length: \(selectedPacketLength)")}
                )
                Divider()
                Text("Received stream")
                    .font(.headline)
                    .fontWeight(.thin)
                ScrollView {
                    Text(AR.recognizerStream)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    // fill width in the beginning, when the string is empty
                    .frame(minWidth: 0, maxWidth: .infinity,
                           minHeight: 0, maxHeight: .infinity,
                           alignment: Alignment.center
                    )
                }
                .frame(width: UIScreen.main.bounds.width-50,
                       height: UIScreen.main.bounds.height-300)
                Button(action: {
                    self.AR.recognizerStream = ""
                }, label: {Text("Clear text")})
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
