//
//  Frame_tvOSApp.swift
//  Frame tvOS
//
//  Created by Noah Hall on 6/6/25.
//
import SwiftUI

@main
struct FrameTVApp: App {
    @State private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView() // Your existing beautiful UI
                    .environment(authManager)
            } else {
                LoginView() // New login screen
                    .environment(authManager)
            }
        }
        .modelContainer(ModelContainer.shared)
    }
}
