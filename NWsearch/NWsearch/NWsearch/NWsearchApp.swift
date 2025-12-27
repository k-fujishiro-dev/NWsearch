//
//  NWsearchApp.swift
//  NWsearch
//
//  Created by Kakeru Fujishiro on 2025/12/27.
//

import SwiftUI

@main
struct NWsearchApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(sessionStore)
                .environmentObject(settingsStore)
                .environmentObject(networkMonitor)
        }
    }
}
