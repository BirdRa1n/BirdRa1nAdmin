// Sources/BirdRa1nAdmin/App/DesignSystem.swift
import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let neon         = Color(red: 0, green: 1, blue: 0.529)       // #00FF87
    static let neonDim      = Color(red: 0, green: 0.8, blue: 0.42)
    static let cyanNeon     = Color(red: 0, green: 0.898, blue: 1)       // #00E5FF
    static let acid         = Color(red: 0.698, green: 1, blue: 0)       // #B2FF00
    static let bgPrimary    = Color(red: 0.02, green: 0.031, blue: 0.059) // #050810
    static let bgCard       = Color(red: 0.047, green: 0.063, blue: 0.094)
    static let bgCardAlt    = Color(red: 0.063, green: 0.082, blue: 0.118)
    static let border       = Color(red: 0.106, green: 0.133, blue: 0.188)
    static let textPrimary  = Color(red: 0.878, green: 0.906, blue: 0.965)
    static let textMuted    = Color(red: 0.4, green: 0.45, blue: 0.55)
    static let danger       = Color(red: 1, green: 0.333, blue: 0.333)   // #FF5555
    static let warning      = Color(red: 1, green: 0.584, blue: 0)       // #FF9500

    // Status colors
    static func statusColor(_ status: String) -> Color {
        switch status {
        case "published": return .neon
        case "draft":     return .warning
        case "archived":  return .textMuted
        case "new":       return .cyanNeon
        case "read":      return .textMuted
        case "replied":   return .neon
        default:          return .textMuted
        }
    }
}

// MARK: - Neon Glow Modifier
struct NeonGlow: ViewModifier {
    var color: Color = .neon
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func neonGlow(color: Color = .neon, radius: CGFloat = 8) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    var hovered: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(hovered ? Color.neon.opacity(0.6) : Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, hovered: Bool = false) -> some View {
        modifier(CardStyle(padding: padding, hovered: hovered))
    }
}

// MARK: - Mono Label Style
struct MonoLabel: ViewModifier {
    var size: CGFloat = 10
    var opacity: Double = 0.5

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .regular, design: .monospaced))
            .tracking(2)
            .textCase(.uppercase)
            .opacity(opacity)
    }
}

extension View {
    func monoLabel(size: CGFloat = 10, opacity: Double = 0.5) -> some View {
        modifier(MonoLabel(size: size, opacity: opacity))
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    var color: Color = .neon

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.statusColor(status).opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.statusColor(status).opacity(0.25), lineWidth: 1)
            )
            .foregroundColor(Color.statusColor(status))
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - Neon Button Style
struct NeonButtonStyle: ButtonStyle {
    var variant: ButtonVariant = .primary

    enum ButtonVariant { case primary, outline, danger }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(2)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background(configuration.isPressed))
            .foregroundColor(foreground)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func background(_ pressed: Bool) -> Color {
        switch variant {
        case .primary: return pressed ? Color.neon.opacity(0.8) : Color.neon
        case .outline: return pressed ? Color.neon.opacity(0.1) : Color.clear
        case .danger:  return pressed ? Color.danger.opacity(0.2) : Color.danger.opacity(0.1)
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: return Color.bgPrimary
        case .outline: return Color.neon
        case .danger:  return Color.danger
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: return Color.clear
        case .outline: return Color.neon.opacity(0.6)
        case .danger:  return Color.danger.opacity(0.4)
        }
    }
}

// MARK: - Terminal Input Style
struct TerminalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.bgCardAlt)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .foregroundColor(Color.textPrimary)
    }
}

// MARK: - Animated Scan Line
struct ScanlineEffect: View {
    @State private var offset: CGFloat = -200

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Color.neon.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    offset = geo.size.height + 80
                }
            }
        }
        .clipped()
    }
}

// MARK: - Loading Spinner
struct NeonSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(Color.neon, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Toast
struct ToastMessage: Equatable {
    let type: ToastType
    let message: String

    enum ToastType { case success, error }
}

struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13))
            Text(toast.message)
                .font(.system(size: 11, design: .monospaced))
        }
        .foregroundColor(toast.type == .success ? .neon : .danger)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            (toast.type == .success ? Color.neon : Color.danger).opacity(0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    (toast.type == .success ? Color.neon : Color.danger).opacity(0.4),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: (toast.type == .success ? Color.neon : Color.danger).opacity(0.2), radius: 12)
    }
}

// MARK: - Confirm Dialog
struct ConfirmDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ConfirmDialogView(
                    title: title,
                    message: message,
                    onConfirm: {
                        isPresented = false
                        onConfirm()
                    },
                    onCancel: { isPresented = false }
                )
            }
    }
}

struct ConfirmDialogView: View {
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.textPrimary)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }

            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                    .buttonStyle(NeonButtonStyle(variant: .outline))
                Button("Confirmar", action: onConfirm)
                    .buttonStyle(NeonButtonStyle(variant: .danger))
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
