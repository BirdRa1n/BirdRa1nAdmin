// BirdRa1nAdmin/Views/Contact/ContactView.swift
import SwiftUI
import Supabase

struct ContactView: View {
    @Binding var toast: ToastMessage?
    @State private var messages: [ContactMessage] = []
    @State private var isLoading = true
    @State private var selected: ContactMessage?
    @State private var filter = "all"

    private let filters = ["all", "new", "read", "replied", "archived"]

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filtros
                Picker("Filtro", selection: $filter) {
                    ForEach(filters, id: \.self) { f in
                        Text(f == "all" ? "Todas" : f.capitalized).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .onChange(of: filter) { _, _ in Task { await loadMessages() } }

                Divider()

                if isLoading {
                    List { ForEach(0..<5) { _ in SkeletonRow() } }.listStyle(.sidebar)
                } else if messages.isEmpty {
                    ContentUnavailableView("Sem mensagens", systemImage: "envelope",
                                          description: Text(filter == "all" ? "Nenhuma mensagem recebida" : "Nenhuma mensagem com status \"\(filter)\""))
                } else {
                    List(messages, id: \.id, selection: $selected) { msg in
                        MsgListRow(msg: msg)
                            .tag(msg)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Contato")
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
        } detail: {
            if let msg = selected {
                MsgDetailView(msg: msg, onUpdateStatus: { id, status in
                    await updateStatus(id, status)
                })
                .id(msg.id)
            } else {
                ContentUnavailableView("Selecione uma mensagem", systemImage: "envelope.open",
                                       description: Text("Escolha uma mensagem na lista ao lado"))
            }
        }
        .onChange(of: selected) { _, new in
            if let msg = new, msg.status == "new" {
                Task { await updateStatus(msg.id, "read") }
            }
        }
        .task { await loadMessages() }
    }

    private func loadMessages() async {
        isLoading = true
        var q = supabase.schema(DB.portfolio).from("contact_messages")
            .select("id, name, email, subject, message, status, created_at")
        if filter != "all" { q = q.eq("status", value: filter) }
        messages = (try? await q.order("created_at", ascending: false).execute().value) ?? []
        isLoading = false
    }

    @MainActor
    private func updateStatus(_ id: String, _ status: String) async {
        try? await supabase.schema(DB.portfolio).from("contact_messages")
            .update(ContactStatusUpdate(status: status)).eq("id", value: id).execute()
        messages = messages.map { m in
            m.id == id
                ? ContactMessage(id: m.id, name: m.name, email: m.email,
                                 subject: m.subject, message: m.message,
                                 status: status, createdAt: m.createdAt)
                : m
        }
        if selected?.id == id { selected = messages.first { $0.id == id } }
        toast = .init(type: .success, message: "Status → \(status)")
    }
}

// MARK: - Message List Row
struct MsgListRow: View {
    let msg: ContactMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                if msg.status == "new" {
                    Circle().fill(.blue).frame(width: 7, height: 7)
                }
                Text(msg.name)
                    .font(.subheadline)
                    .fontWeight(msg.status == "new" ? .semibold : .regular)
                Spacer()
                Text(formatDate(msg.createdAt)).font(.caption2).foregroundStyle(.tertiary)
            }
            Text(msg.subject ?? "Sem assunto").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(msg.message).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Message Detail
struct MsgDetailView: View {
    let msg: ContactMessage
    let onUpdateStatus: (String, String) async -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(msg.name).font(.title2).fontWeight(.bold)
                            Link(msg.email, destination: URL(string: "mailto:\(msg.email)")!)
                                .font(.subheadline).foregroundStyle(.tint)
                        }
                        Spacer()
                        StatusBadge(status: msg.status ?? "new")
                    }

                    HStack {
                        Label(msg.subject ?? "Sem assunto", systemImage: "text.bubble")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Label(formatDate(msg.createdAt), systemImage: "calendar")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .padding(20)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Corpo
                Text(msg.message)
                    .font(.body)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Ações de status
                VStack(alignment: .leading, spacing: 10) {
                    Text("Atualizar Status")
                        .font(.footnote).fontWeight(.semibold)
                        .foregroundStyle(.secondary).textCase(.uppercase)

                    HStack(spacing: 8) {
                        ForEach(["new", "read", "replied", "archived"], id: \.self) { s in
                            Button {
                                Task { await onUpdateStatus(msg.id, s) }
                            } label: {
                                Label(s.capitalized, systemImage: iconFor(s))
                                    .font(.caption)
                                    .fontWeight(msg.status == s ? .semibold : .regular)
                            }
                            .buttonStyle(.bordered)
                            .tint(msg.status == s ? .accentColor : .secondary)
                        }

                        Spacer()

                        // Botão responder
                        Button {
                            let subject = "Re: \(msg.subject ?? "")"
                            let enc = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "mailto:\(msg.email)?subject=\(enc)") {
                                NSWorkspace.shared.open(url)
                            }
                            Task { await onUpdateStatus(msg.id, "replied") }
                        } label: {
                            Label("Responder", systemImage: "arrowshape.turn.up.left.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(msg.name)
        .navigationSubtitle(msg.subject ?? "")
    }

    private func iconFor(_ s: String) -> String {
        switch s {
        case "new": return "sparkle"
        case "read": return "envelope.open"
        case "replied": return "arrowshape.turn.up.left"
        case "archived": return "archivebox"
        default: return "circle"
        }
    }
}
