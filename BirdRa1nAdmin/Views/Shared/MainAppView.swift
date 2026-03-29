// Sources/BirdRa1nAdmin/Views/Shared/MainAppView.swift
import SwiftUI

enum AdminSection: String, CaseIterable, Identifiable {
    case dashboard    = "Dashboard"
    case projects     = "Projetos"
    case blog         = "Blog"
    case certificates = "Certificados"
    case apps         = "Apps"
    case contact      = "Contato"
    case tags         = "Tags"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:    return "square.grid.2x2"
        case .projects:     return "folder"
        case .blog:         return "doc.text"
        case .certificates: return "rosette"
        case .apps:         return "iphone"
        case .contact:      return "envelope"
        case .tags:         return "tag"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:    return .neon
        case .projects:     return .neon
        case .blog:         return .neon
        case .certificates: return .cyanNeon
        case .apps:         return .acid
        case .contact:      return .warning
        case .tags:         return .neon
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var selectedSection: AdminSection = .dashboard
    @State private var toast: ToastMessage?

    var body: some View {
        NavigationSplitView {
            SidebarView(selected: $selectedSection)
        } detail: {
            DetailView(section: selectedSection, toast: $toast)
                .background(Color.bgPrimary)
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            if let toast {
                ToastView(toast: toast)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(99)
            }
        }
        .animation(.spring(duration: 0.3), value: toast?.message)
        .onChange(of: toast) { _, new in
            guard new != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation { toast = nil }
            }
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var authStore: AuthStore
    @Binding var selected: AdminSection

    var body: some View {
        VStack(spacing: 0) {
            // Logo header
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.neon)
                            .frame(width: 34, height: 34)
                        Text("BR")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.bgPrimary)
                    }
                    .neonGlow(radius: 12)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("ADMIN")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.neon)
                        Text("PANEL")
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            Divider().background(Color.border)

            // Nav items
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(AdminSection.allCases) { section in
                        SidebarItem(
                            section: section,
                            isSelected: selected == section
                        ) {
                            selected = section
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }

            Spacer()
            Divider().background(Color.border)

            // User footer
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.neon.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.neon.opacity(0.2), lineWidth: 1)
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.neon)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(authStore.currentUser?.displayName ?? "Admin")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        Text(authStore.currentUser?.role?.uppercased() ?? "ADMIN")
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)

                Button {
                    Task { await authStore.signOut() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 11))
                        Text("SIGN_OUT")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .foregroundColor(.danger.opacity(0.7))
                .contentShape(Rectangle())
                .hoverEffect()
            }
            .padding(.vertical, 12)
        }
        .background(Color.bgCard)
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
    }
}

struct SidebarItem: View {
    let section: AdminSection
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? section.color : .textMuted)
                    .frame(width: 18)

                Text(section.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(isSelected ? section.color : .textPrimary.opacity(0.6))

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(section.color.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(isSelected ? section.color.opacity(0.1) : (hovered ? Color.bgCardAlt : Color.clear))
            )
            .overlay(
                Rectangle()
                    .fill(isSelected ? section.color : Color.clear)
                    .frame(width: 2)
                    .clipShape(RoundedRectangle(cornerRadius: 1)),
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

// MARK: - Detail Router
struct DetailView: View {
    let section: AdminSection
    @Binding var toast: ToastMessage?

    var body: some View {
        switch section {
        case .dashboard:    DashboardView(toast: $toast)
        case .projects:     ProjectsListView(toast: $toast)
        case .blog:         BlogListView(toast: $toast)
        case .certificates: CertificatesView(toast: $toast)
        case .apps:         AppsListView(toast: $toast)
        case .contact:      ContactView(toast: $toast)
        case .tags:         TagsView(toast: $toast)
        }
    }
}

// MARK: - Hover effect extension
extension View {
    func hoverEffect() -> some View {
        self.onHover { _ in }
    }
}
