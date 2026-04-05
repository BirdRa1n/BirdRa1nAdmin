// BirdRa1nAdmin/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        if authStore.isLoading {
            // Splash de inicialização — preenche a janela inteira
            VStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                ProgressView()
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        } else if authStore.isAuthenticated {
            MainAppView()
                .transition(.opacity)
        } else {
            LoginView()
                .frame(minWidth: 420, minHeight: 560)
                .transition(.opacity)
        }
    }
}
