//
//  ContentView.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 03.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State var selectedView = 0
    @State var message = ""
    @State var TC = TransmissionController()
    
    // wrap in @ObservedObject to catch inner property changes
    @ObservedObject var AR = AudioRecognizer.sharedRecognizer()
        
    var body: some View {
        TabView(selection: $selectedView) {
            // =============== Tab 1 : send ===============
            HStack {
                //TextField(text: $message)
                TextField("Message", text: $message)
                Button(action: {
                    self.TC.send(message: self.message)
                    self.message = ""
                }) {
                    Text("Send")
                }
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
                    self.AR.isRunning ? self.AR.stopRecognition() : self.AR.startRecognition()
                }) {
                    Text(AR.isRunning ? "Stop" : "Start")
                        .font(.title)
                }
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
                       height: UIScreen.main.bounds.height-250)
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
