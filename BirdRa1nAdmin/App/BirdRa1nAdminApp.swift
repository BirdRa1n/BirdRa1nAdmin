// Sources/BirdRa1nAdmin/App/BirdRa1nAdminApp.swift
import SwiftUI

@main
struct BirdRa1nAdminApp: App {
    @StateObject private var authStore = AuthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
