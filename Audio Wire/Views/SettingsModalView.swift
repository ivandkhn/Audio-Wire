//
//  SettingsModalView.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 25.03.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import SwiftUI

struct StepView: View {
    var caption: String
    var infoText: String
    var range: ClosedRange<Int>
    @Binding var value: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.infoText).font(.footnote).fontWeight(.light)
            Stepper(value: $value,
                    in: range,
                    label: { Text("\(self.caption): \(value)")}
            )
            Divider()
        }
    }
}

struct SettingsModalView: View {
    let avaliablePacketLength = 1...20
    let avaliableMagnitudesCount = 1...5

    @ObservedObject var globals = GlobalParameters.getSharedInstance()
    @Binding var showModal: Bool
    @State var selectedPacketLength: Int = GlobalParameters.getSharedInstance().packetLength
    @State var selectedMagnitudesCount: Int = GlobalParameters.getSharedInstance().averageMagnitudesBandsCount
    
    var body: some View {
        VStack {
            Text("Settings").font(.title)
            Spacer()
            
            StepView(caption: "Packet length",
                     infoText: "Select how long the single character transmission should last. Lesser values lead to quicker transmission, however, error rate increases.",
                     range: avaliablePacketLength,
                     value: $selectedPacketLength)
            
            StepView(caption: "Magnitudes count",
                     infoText: "Select how many nearby band are analyzed to count the average magnitudes for a specific frequency.",
                     range: avaliableMagnitudesCount,
                     value: $selectedMagnitudesCount)
            
            Spacer()
            Button("OK") {
                self.globals.packetLength = self.selectedPacketLength
                self.globals.averageMagnitudesBandsCount = self.selectedMagnitudesCount
                self.showModal.toggle()
            }
        }.padding()
    }
}

struct SettingsModalView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsModalView(showModal: .constant(true)).environment(\.colorScheme, .light)
    }
}
