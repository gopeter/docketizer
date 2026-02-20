//
//  RootView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import SwiftUI

struct RootView: View {
    @AppStorage("apiKey") var apiKey: String?
    
    var body: some View {
        if apiKey == nil {
            LoginView().frame(width: 300)
        } else {
            ContentView().frame(width: 640, height: 300)
        }
    }
}

#Preview {
    RootView()
}
