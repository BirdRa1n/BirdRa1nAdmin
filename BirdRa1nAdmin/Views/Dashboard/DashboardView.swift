// BirdRa1nAdmin/Views/Dashboard/DashboardView.swift
import SwiftUI
import Supabase

struct DashboardView: View {
    @Binding var toast: ToastMessage?
    @EnvironmentObject var authStore: AuthStore
    @State private var stats = DashboardStats()
    @State private var isLoading = true
    @State private var loadError: String?

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Bom dia" }
        if h < 18 { return "Boa tarde" }
        return "Boa noite"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Saudação
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting), \(authStore.currentUser?.firstWord ?? "Admin") 👋")
                        .font(.largeTitle).fontWeight(.bold)
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Erro de carregamento
                if let err = loadError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote).foregroundStyle(.orange)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if isLoading {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(0..<6) { _ in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.secondary.opacity(0.1))
                                .frame(height: 88)
                                .shimmer()
                        }
                    }
                } else {
                    // Métricas
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        StatTile(value: stats.projects,    label: "Projetos",        icon: "folder.fill",       tint: .blue)
                        StatTile(value: stats.posts,       label: "Posts",            icon: "doc.richtext.fill", tint: .indigo)
                        StatTile(value: stats.newMessages, label: "Novas Mensagens",  icon: "envelope.fill",     tint: .orange)
                        StatTile(value: stats.certificates,label: "Certificados",     icon: "rosette",           tint: .teal)
                        StatTile(value: stats.apps,        label: "Apps",             icon: "iphone",            tint: .purple)
                        StatTile(value: stats.totalViews,  label: "Total de Views",   icon: "eye.fill",          tint: .green)
                    }

                    // Seções recentes
                    HStack(alignment: .top, spacing: 16) {
                        RecentCard(title: "Posts Recentes") {
                            if stats.recentPosts.isEmpty {
                                Text("Nenhum post ainda.")
                                    .font(.subheadline).foregroundStyle(.secondary).padding(16)
                            } else {
                                ForEach(Array(stats.recentPosts.enumerated()), id: \.element.id) { i, post in
                                    if i > 0 { Divider().padding(.leading, 16) }
                                    HStack(spacing: 10) {
                                        Image(systemName: "doc.richtext")
                                            .foregroundStyle(.secondary).frame(width: 18)
                                        Text(post.title).font(.subheadline).lineLimit(1)
                                        Spacer()
                                        StatusBadge(status: post.status)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                }
                            }
                        }

                        RecentCard(title: "Mensagens Recentes") {
                            if stats.recentMessages.isEmpty {
                                Text("Nenhuma mensagem ainda.")
                                    .font(.subheadline).foregroundStyle(.secondary).padding(16)
                            } else {
                                ForEach(Array(stats.recentMessages.enumerated()), id: \.element.id) { i, msg in
                                    if i > 0 { Divider().padding(.leading, 16) }
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle().fill(.tint.opacity(0.12)).frame(width: 28, height: 28)
                                            Text(String(msg.name.prefix(1)).uppercased())
                                                .font(.caption).fontWeight(.bold).foregroundStyle(.tint)
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(msg.name).font(.subheadline).fontWeight(.medium).lineLimit(1)
                                            Text(msg.subject ?? "Sem assunto")
                                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Spacer()
                                        if msg.status == "new" {
                                            Circle().fill(.blue).frame(width: 7, height: 7)
                                        }
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadStats() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Recarregar dados")
                .disabled(isLoading)
            }
        }
        .task { await loadStats() }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }

    private func loadStats() async {
        isLoading = true
        loadError = nil

        do {
            // Busca em paralelo — schema explícito em cada chamada
            async let projectsResult: [Project] = supabase
                .schema(DB.portfolio).from("projects")
                .select("id, views_count")
                .execute().value

            async let postsResult: [BlogPost] = supabase
                .schema(DB.blog).from("posts")
                .select("id, title, slug, status, created_at")
                .order("created_at", ascending: false)
                .limit(5)
                .execute().value

            async let msgsResult: [ContactMessage] = supabase
                .schema(DB.portfolio).from("contact_messages")
                .select("id, name, email, subject, status, created_at")
                .order("created_at", ascending: false)
                .limit(5)
                .execute().value

            async let newMsgsResult: [ContactMessage] = supabase
                .schema(DB.portfolio).from("contact_messages")
                .select("id")
                .eq("status", value: "new")
                .execute().value

            async let certsResult: [Certificate] = supabase
                .schema(DB.portfolio).from("certificates")
                .select("id")
                .execute().value

            async let appsResult: [StoreApp] = supabase
                .schema(DB.store).from("apps")
                .select("id")
                .execute().value

            let (projects, posts, msgs, newMsgs, certs, apps) = try await (
                projectsResult, postsResult, msgsResult,
                newMsgsResult, certsResult, appsResult
            )

            stats.projects       = projects.count
            stats.posts          = posts.count
            stats.newMessages    = newMsgs.count
            stats.certificates   = certs.count
            stats.apps           = apps.count
            stats.totalViews     = projects.compactMap { $0.viewsCount }.reduce(0, +)
            stats.recentPosts    = posts
            stats.recentMessages = msgs

        } catch {
            loadError = "Erro ao carregar dados: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Stat Tile
struct StatTile: View {
    let value: Int
    let label: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title2).fontWeight(.bold).monospacedDigit()
                Text(label)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Recent Card
struct RecentCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.headline)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            Divider()
            content()
        }
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity)
    }
}
