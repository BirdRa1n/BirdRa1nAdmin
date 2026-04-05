// BirdRa1nAdmin/Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 4) {
                    Text("BirdRa1n Admin")
                        .font(.title2).fontWeight(.semibold)
                    Text("Painel de administração")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 36)

            // Form
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email")
                        .font(.footnote).fontWeight(.medium).foregroundStyle(.secondary)
                    TextField("admin@exemplo.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .frame(height: 32)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Senha")
                        .font(.footnote).fontWeight(.medium).foregroundStyle(.secondary)
                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .frame(height: 32)
                        .onSubmit { signIn() }
                }

                if let err = authStore.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }

                Button(action: signIn) {
                    Group {
                        if authStore.isLoading {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text("Entrando...")
                            }
                        } else {
                            Text("Entrar")
                        }
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(authStore.isLoading || email.isEmpty || password.isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 40)

            Spacer()

            Text("Acesso restrito a administradores")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
        .frame(width: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func signIn() {
        Task { await authStore.signIn(email: email, password: password) }
    }
}
