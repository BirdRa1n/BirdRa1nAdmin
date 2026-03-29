// Sources/BirdRa1nAdmin/Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            // Background
            Color.bgPrimary.ignoresSafeArea()

            // Grid overlay
            GridOverlay()

            // Scan line
            ScanlineEffect()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Terminal title bar
                HStack(spacing: 8) {
                    Circle().fill(Color(red: 1, green: 0.373, blue: 0.341)).frame(width: 12, height: 12)
                    Circle().fill(Color(red: 0.996, green: 0.737, blue: 0.18)).frame(width: 12, height: 12)
                    Circle().fill(Color(red: 0.157, green: 0.784, blue: 0.251)).frame(width: 12, height: 12)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "terminal")
                            .font(.system(size: 10))
                            .foregroundColor(.neon.opacity(0.5))
                        Text("admin.sh — bash")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.textMuted.opacity(0.5))
                    }
                    Spacer()
                    // Balance
                    HStack(spacing: 8) {
                        ForEach(0..<3) { _ in Circle().frame(width: 12, height: 12).opacity(0) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.bgCardAlt)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)

                // Content
                VStack(spacing: 28) {
                    // Lock icon
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.neon.opacity(0.08))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.neon.opacity(0.2), lineWidth: 1)
                                )
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.neon)
                        }
                        .neonGlow(radius: 16)

                        VStack(spacing: 4) {
                            Text("Access Required")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text("// authenticate to continue")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.textMuted)
                        }
                    }

                    // Form
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL")
                                .monoLabel()
                                .foregroundColor(.textMuted)
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted.opacity(0.5))
                                TextField("admin@example.com", text: $email)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.bgCardAlt)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(email.isEmpty ? Color.border : Color.neon.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PASSWORD")
                                .monoLabel()
                                .foregroundColor(.textMuted)
                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted.opacity(0.5))
                                if isPasswordVisible {
                                    TextField("••••••••", text: $password)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.textPrimary)
                                } else {
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.textPrimary)
                                }
                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.bgCardAlt)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(password.isEmpty ? Color.border : Color.neon.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        }

                        // Error
                        if let err = authStore.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                Text("// Error: \(err)")
                                    .font(.system(size: 10, design: .monospaced))
                            }
                            .foregroundColor(.danger)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.danger.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.danger.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        }

                        // Submit
                        Button {
                            Task { await authStore.signIn(email: email, password: password) }
                        } label: {
                            HStack(spacing: 8) {
                                if authStore.isLoading {
                                    NeonSpinner()
                                    Text("AUTHENTICATING...")
                                } else {
                                    Text("ENTER_PANEL")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NeonButtonStyle(variant: .primary))
                        .disabled(authStore.isLoading || email.isEmpty || password.isEmpty)
                        .keyboardShortcut(.return)
                    }
                }
                .padding(32)
            }
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(width: 400)
            .shadow(color: Color.neon.opacity(0.05), radius: 40)
        }
    }
}

// MARK: - Grid Overlay
struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let step: CGFloat = 50
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                ctx.stroke(path, with: .color(Color.neon.opacity(0.025)), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}
