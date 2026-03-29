// Sources/BirdRa1nAdmin/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                MainAppView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authStore.isAuthenticated)
        .frame(minWidth: authStore.isAuthenticated ? 900 : 420,
               minHeight: authStore.isAuthenticated ? 600 : 520)
    }
}
