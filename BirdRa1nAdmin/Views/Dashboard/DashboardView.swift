// Sources/BirdRa1nAdmin/Views/Dashboard/DashboardView.swift
import SwiftUI
import Supabase

struct DashboardView: View {
    @Binding var toast: ToastMessage?
    @State private var stats = DashboardStats()
    @State private var isLoading = true
    @EnvironmentObject var authStore: AuthStore

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Bom dia" }
        if h < 18 { return "Boa tarde" }
        return "Boa noite"
    }

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "EEEE, d 'de' MMMM 'de' yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("// dashboard")
                        .font(.system(size: 10, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.neon.opacity(0.6))

                    Text("\(greeting), \(authStore.currentUser?.firstWord ?? "Admin") 👋")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text(dateString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.textMuted)
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                if isLoading {
                    StatsGridSkeleton()
                        .padding(.horizontal, 28)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                        StatCard(label: "Projetos",    value: stats.projects,     icon: "folder",        color: .neon)
                        StatCard(label: "Posts",       value: stats.posts,        icon: "doc.text",      color: .neon)
                        StatCard(label: "Mensagens",   value: stats.newMessages,  icon: "envelope",      color: .warning)
                        StatCard(label: "Certificados",value: stats.certificates, icon: "rosette",       color: .cyanNeon)
                        StatCard(label: "Apps",        value: stats.apps,         icon: "iphone",        color: .acid)
                    }
                    .padding(.horizontal, 28)

                    HStack(spacing: 12) {
                        Image(systemName: "eye").foregroundColor(.neon)
                        Text("Total de views em projetos:")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.textPrimary)
                        Text(stats.totalViews.formatted())
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.neon)
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.neon.opacity(0.4))
                    }
                    .padding(16)
                    .background(Color.neon.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.neon.opacity(0.15), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal, 28)

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Posts Recentes")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(1).foregroundColor(.textMuted).textCase(.uppercase)
                                Spacer()
                            }
                            if stats.recentPosts.isEmpty {
                                Text("// Nenhum post ainda")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.textMuted.opacity(0.4)).padding(.vertical, 8)
                            } else {
                                ForEach(stats.recentPosts) { post in RecentPostRow(post: post) }
                            }
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Mensagens Recentes")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(1).foregroundColor(.textMuted).textCase(.uppercase)
                                Spacer()
                            }
                            if stats.recentMessages.isEmpty {
                                Text("// Nenhuma mensagem ainda")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.textMuted.opacity(0.4)).padding(.vertical, 8)
                            } else {
                                ForEach(stats.recentMessages) { msg in RecentMessageRow(msg: msg) }
                            }
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.horizontal, 28)
                }

                Spacer(minLength: 28)
            }
        }
        .background(Color.bgPrimary)
        .task { await loadStats() }
    }

    private func loadStats() async {
        isLoading = true
        async let projects: [Project] = (try? await supabase.schema("portfolio").from("projects")
            .select("id,views_count").execute().value) ?? []
        async let posts: [BlogPost] = (try? await supabase.schema("blog").from("posts")
            .select("id,title,slug,status,created_at").limit(5).execute().value) ?? []
        async let msgs: [ContactMessage] = (try? await supabase.schema("portfolio").from("contact_messages")
            .select("id,name,email,subject,status,created_at").order("created_at", ascending: false).limit(5).execute().value) ?? []
        async let newMsgs: [ContactMessage] = (try? await supabase.schema("portfolio").from("contact_messages")
            .select("id").eq("status", value: "new").execute().value) ?? []
        async let certs: [Certificate] = (try? await supabase.schema("portfolio").from("certificates")
            .select("id").execute().value) ?? []
        async let apps: [StoreApp] = (try? await supabase.schema("store").from("apps")
            .select("id").execute().value) ?? []

        let (p, po, m, nm, c, a) = await (projects, posts, msgs, newMsgs, certs, apps)
        stats.projects      = p.count
        stats.posts         = po.count
        stats.newMessages   = nm.count
        stats.certificates  = c.count
        stats.apps          = a.count
        stats.totalViews    = p.compactMap { $0.viewsCount }.reduce(0, +)
        stats.recentPosts   = po
        stats.recentMessages = m
        isLoading = false
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(color.opacity(0.25), lineWidth: 1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 10))
                    .foregroundColor(.textMuted.opacity(hovered ? 0.5 : 0.2))
            }
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .neonGlow(color: color, radius: hovered ? 8 : 0)
            Text(label.uppercased())
                .font(.system(size: 9, design: .monospaced)).tracking(2).foregroundColor(.textMuted)
        }
        .padding(16).background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(hovered ? color.opacity(0.4) : Color.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: hovered)
    }
}

// MARK: - Recent rows
struct RecentPostRow: View {
    let post: BlogPost
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text").font(.system(size: 11)).foregroundColor(.neon.opacity(0.5))
            Text(post.title).font(.system(size: 11)).foregroundColor(.textPrimary).lineLimit(1)
            Spacer()
            if let status = post.status { StatusBadge(status: status) }
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(Color.bgCardAlt.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct RecentMessageRow: View {
    let msg: ContactMessage
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.neon.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.neon.opacity(0.15), lineWidth: 1))
                    .frame(width: 24, height: 24)
                Text(String(msg.name.prefix(1)).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.neon)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(msg.name).font(.system(size: 11, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(1)
                Text(msg.subject ?? "").font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted).lineLimit(1)
            }
            Spacer()
            if msg.status == "new" {
                Circle().fill(Color.neon).frame(width: 6, height: 6).shadow(color: .neon, radius: 3)
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(Color.bgCardAlt.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Skeleton
struct StatsGridSkeleton: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
            ForEach(0..<5) { _ in
                RoundedRectangle(cornerRadius: 4).fill(Color.bgCard).frame(height: 110)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
                    .shimmer()
            }
        }
    }
}

// MARK: - Shimmer
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: phase - 0.3),
                    .init(color: Color.neon.opacity(0.04), location: phase),
                    .init(color: .clear, location: phase + 0.3),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            .onAppear { phase = 1.3 }
        )
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}
