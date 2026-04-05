// BirdRa1nAdmin/Views/Shared/MainAppView.swift
import SwiftUI

// MARK: - Seções
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
        case .blog:         return "doc.richtext"
        case .certificates: return "rosette"
        case .apps:         return "iphone"
        case .contact:      return "envelope"
        case .tags:         return "tag"
        }
    }
}

// MARK: - Main
struct MainAppView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var selected: AdminSection = .dashboard
    @State private var toast: ToastMessage?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selected: $selected)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
                Group {
                    switch selected {
                    case .dashboard:    DashboardView(toast: $toast)
                    case .projects:     ProjectsListView(toast: $toast)
                    case .blog:         BlogListView(toast: $toast)
                    case .certificates: CertificatesView(toast: $toast)
                    case .apps:         AppsListView(toast: $toast)
                    case .contact:      ContactView(toast: $toast)
                    case .tags:         TagsView(toast: $toast)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .id(selected)
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .bottom) {
            if let t = toast {
                ToastView(toast: t)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toast?.message)
        .onChange(of: toast) { _, new in
            guard new != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { toast = nil }
            }
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var authStore: AuthStore
    @Binding var selected: AdminSection

    private let groups: [(String, [AdminSection])] = [
        ("Geral",    [.dashboard]),
        ("Conteúdo", [.projects, .blog, .certificates]),
        ("Store",    [.apps]),
        ("Gestão",   [.contact, .tags]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // A List ocupa todo o espaço restante
            List(selection: $selected) {
                ForEach(groups, id: \.0) { name, items in
                    Section(name) {
                        ForEach(items) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("BirdRa1n")

            // Separador e footer ficam ABAIXO da lista, com altura garantida
            // Não usa safeAreaInset para evitar o corte do avatar
            Divider()
            UserFooterView()
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - User Footer
struct UserFooterView: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text(String(authStore.currentUser?.firstWord.prefix(1).uppercased() ?? "A"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(authStore.currentUser?.displayName ?? "Admin")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text((authStore.currentUser?.role ?? "admin").capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                Task { await authStore.signOut() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Sair da conta")
        }
    }
}
