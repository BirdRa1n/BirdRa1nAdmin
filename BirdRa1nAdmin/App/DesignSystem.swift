// BirdRa1nAdmin/App/DesignSystem.swift
import SwiftUI

// MARK: - Status
extension Color {
    static func statusColor(_ status: String) -> Color {
        switch status {
        case "published": return .green
        case "draft":     return .orange
        case "archived":  return Color(nsColor: .systemGray)
        case "new":       return .blue
        case "read":      return Color(nsColor: .systemGray)
        case "replied":   return .green
        default:          return Color(nsColor: .systemGray)
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    var color: Color = .accentColor

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String

    private var icon: String {
        switch status {
        case "published": return "checkmark.circle.fill"
        case "draft":     return "pencil.circle.fill"
        case "archived":  return "archivebox.fill"
        case "new":       return "sparkle"
        case "read":      return "envelope.open.fill"
        case "replied":   return "arrowshape.turn.up.left.fill"
        default:          return "circle.fill"
        }
    }

    var body: some View {
        Label(status.capitalized, systemImage: icon)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color.statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.statusColor(status).opacity(0.1))
            .clipShape(Capsule())
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
                .foregroundStyle(toast.type == .success ? .green : .red)
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > w, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, sz.height); x += sz.width + spacing
        }
        return CGSize(width: w, height: max(y + rowH, 0))
    }

    func placeSubviews(in b: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = b.minX; var y = b.minY; var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > b.maxX, x > b.minX { y += rowH + spacing; x = b.minX; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            rowH = max(rowH, sz.height); x += sz.width + spacing
        }
    }
}

// MARK: - Shimmer
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: phase - 0.3),
                    .init(color: .white.opacity(0.12), location: phase),
                    .init(color: .clear, location: phase + 0.3)
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: phase)
            .onAppear { phase = 1.3 }
        )
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

// MARK: - Helpers globais
func slugify(_ text: String) -> String {
    (text.lowercased()
        .applyingTransform(.toLatin, reverse: false)?
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
        .joined(separator: "-")) ?? text
}

func formatDate(_ iso: String?) -> String {
    guard let iso else { return "—" }
    let a = ISO8601DateFormatter(); a.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let b = ISO8601DateFormatter(); b.formatOptions = [.withInternetDateTime]
    guard let d = a.date(from: iso) ?? b.date(from: iso) else { return "—" }
    return d.formatted(date: .abbreviated, time: .omitted)
}
