//
//  SettingsModalView.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 25.03.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.
//

import SwiftUI

struct SettingsModalView: View {
    // 1.
    @Binding var showModal: Bool
    
    var body: some View {
        VStack {
            Text("Inside Modal View")
                .padding()
            // 2.
            Button("Dismiss") {
                self.showModal.toggle()
            }
        }
    }
}

struct SettingsModalView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsModalView(showModal: .constant(true)).environment(\.colorScheme, .dark)
    }
}
