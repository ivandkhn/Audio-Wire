//
//  ContentView.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 03.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    let avaliablePacketLength = Array(1...20)
    
    var colors = ["Red", "Green", "Blue", "Tartan"]
    @State private var selectedColor = 0
    
    @State var selectedView = 0
    @State var selectedPacketLength: Int = GlobalParameters.Transmission.packetLength
    @State var message = ""
    @State var TC = TransmissionController()
    
    // wrap in @ObservedObject to catch inner property changes
    @ObservedObject var AR = AudioRecognizer.sharedRecognizer()
        
    var body: some View {
        TabView(selection: $selectedView) {
            // =============== Tab 1 : send ===============
            VStack {
                HStack {
                    //TextField(text: $message)
                    TextField("Message", text: $message)
                    Button(action: {
                        self.TC.setNewPacketLength(newPacketLength: self.selectedPacketLength)
                        self.TC.send(message: self.message)
                        self.message = ""
                    }) {
                        Text("Send")
                    }
                }
                Stepper(value: $selectedPacketLength,
                        in: 1...20,
                        onEditingChanged: { _ in
                            self.TC.setNewPacketLength(newPacketLength: self.selectedPacketLength)
                        },
                        label: { Text("Packet length: \(selectedPacketLength)")}
                )
            }
            .padding()
            .tabItem {
                Image(systemName: "arrow.up")
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
                        in: 1...20,
                        onEditingChanged: { _ in
                            self.AR.setNewPacketLength(newPacketLength: self.selectedPacketLength)
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
                Image(systemName: "arrow.down")
                Text("Receive")
            }
            .tag(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(selectedView: 0).environment(\.colorScheme, .dark)
            ContentView(selectedView: 1).environment(\.colorScheme, .dark)
        }
    }
}
