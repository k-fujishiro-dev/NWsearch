//
//  ContentView.swift
//  NWsearch
//
//  Created by Kakeru Fujishiro on 2025/12/27.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
        .environmentObject(SettingsStore())
        .environmentObject(NetworkMonitor())
}
