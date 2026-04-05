// BirdRa1nAdmin/App/BirdRa1nAdminApp.swift
import SwiftUI

@main
struct BirdRa1nAdminApp: App {
    @StateObject private var authStore = AuthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
        }
        .defaultSize(width: 1100, height: 720)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
