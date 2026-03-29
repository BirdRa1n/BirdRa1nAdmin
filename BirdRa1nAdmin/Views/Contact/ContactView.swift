// Sources/BirdRa1nAdmin/Views/Contact/ContactView.swift
import SwiftUI
import Supabase

struct ContactView: View {
    @Binding var toast: ToastMessage?
    @State private var messages: [ContactMessage] = []
    @State private var isLoading = true
    @State private var selected: ContactMessage? = nil
    @State private var filter = "all"

    private let filters = ["all", "new", "read", "replied", "archived"]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contato").font(.system(size: 26, weight: .bold)).foregroundColor(.textPrimary)
                        Text("// portfolio.contact_messages").font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted)
                    }
                    Spacer()
                }
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { f in
                        Button {
                            filter = f
                            Task { await loadMessages() }
                        } label: {
                            Text(f.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(filter == f ? Color.neon.opacity(0.1) : Color.bgCard)
                                .foregroundColor(filter == f ? .neon : .textMuted)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(filter == f ? Color.neon.opacity(0.5) : Color.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 14)
            SectionDivider()

            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    if isLoading {
                        ForEach(0..<5) { _ in
                            RoundedRectangle(cornerRadius: 3).fill(Color.bgCard).frame(height: 72)
                                .shimmer().padding(.horizontal, 10).padding(.vertical, 4)
                        }
                    } else if messages.isEmpty {
                        EmptyStateView(icon: "envelope", title: "// Nenhuma mensagem")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(messages) { msg in
                                    MessageListRow(msg: msg, isSelected: selected?.id == msg.id) {
                                        selected = msg
                                        if msg.status == "new" { Task { await updateStatus(msg.id, "read") } }
                                    }
                                }
                            }
                            .padding(8)
                        }
                    }
                }
                .frame(width: 300).background(Color.bgCard)
                .overlay(Rectangle().frame(width: 1).foregroundColor(Color.border), alignment: .trailing)

                if let msg = selected {
                    MessageDetailView(msg: msg) { id, status in await updateStatus(id, status) }.id(msg.id)
                } else {
                    VStack {
                        Image(systemName: "envelope.open").font(.system(size: 32, weight: .light)).foregroundColor(.textMuted.opacity(0.3))
                        Text("// Selecione uma mensagem").font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4)).padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.bgPrimary)
                }
            }
        }
        .background(Color.bgPrimary)
        .task { await loadMessages() }
    }

    private func loadMessages() async {
        isLoading = true
        var query = supabase.schema("portfolio").from("contact_messages")
            .select("id,name,email,subject,message,status,created_at")
        
        if filter != "all" {
            query = query.eq("status", value: filter)
        }
        
        messages = (try? await query.order("created_at", ascending: false).execute().value) ?? []
        isLoading = false
    }

    @MainActor
    private func updateStatus(_ id: String, _ status: String) async {
        struct Payload: Encodable { let status: String }
        try? await supabase.schema("portfolio").from("contact_messages")
            .update(Payload(status: status)).eq("id", value: id).execute()
        messages = messages.map {
            $0.id == id ? ContactMessage(id: $0.id, name: $0.name, email: $0.email,
                                         subject: $0.subject, message: $0.message,
                                         status: status, createdAt: $0.createdAt) : $0
        }
        if selected?.id == id { selected = messages.first(where: { $0.id == id }) }
    }
}

// MARK: - Message List Row
struct MessageListRow: View {
    let msg: ContactMessage
    let isSelected: Bool
    let onTap: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if msg.status == "new" { Circle().fill(Color.cyanNeon).frame(width: 6, height: 6).shadow(color: .cyanNeon, radius: 3) }
                    Text(msg.name).font(.system(size: 12, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(1)
                    Spacer()
                    Text(formatDate(msg.createdAt)).font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted.opacity(0.5))
                }
                Text(msg.subject ?? "Sem assunto").font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted).lineLimit(1)
                Text(msg.message).font(.system(size: 10)).foregroundColor(.textMuted.opacity(0.5)).lineLimit(1)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(isSelected ? Color.neon.opacity(0.06) : (hovered ? Color.bgCardAlt : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(isSelected ? Color.neon.opacity(0.3) : Color.clear, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain).onHover { hovered = $0 }
    }
}

// MARK: - Message Detail
struct MessageDetailView: View {
    let msg: ContactMessage
    let onUpdateStatus: (String, String) async -> Void
    private let statuses = ["new", "read", "replied", "archived"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Text(msg.name).font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
                            StatusBadge(status: msg.status ?? "new")
                        }
                        Text(msg.email).font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 18).background(Color.bgCard)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ASSUNTO").monoLabel(size: 9).foregroundColor(.textMuted)
                    Text(msg.subject ?? "Sem assunto").font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary)
                }
                Spacer()
                Text(formatDate(msg.createdAt)).font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
            }
            .padding(.horizontal, 24).padding(.vertical, 14).background(Color.bgCardAlt)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)

            ScrollView {
                Text(msg.message).font(.system(size: 13)).foregroundColor(.textPrimary.opacity(0.85))
                    .lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }

            HStack(spacing: 10) {
                Spacer()
                ForEach(statuses, id: \.self) { status in
                    Button { Task { await onUpdateStatus(msg.id, status) } } label: {
                        Text(status.uppercased())
                            .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(msg.status == status ? Color.neon.opacity(0.1) : Color.bgCardAlt)
                            .foregroundColor(msg.status == status ? .neon : .textMuted)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(msg.status == status ? Color.neon.opacity(0.5) : Color.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    let subject = "Re: \(msg.subject ?? "")"
                    let mailto = "mailto:\(msg.email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)"
                    if let url = URL(string: mailto) { NSWorkspace.shared.open(url) }
                    Task { await onUpdateStatus(msg.id, "replied") }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill").font(.system(size: 11))
                        Text("RESPONDER")
                    }
                }
                .buttonStyle(NeonButtonStyle(variant: .primary))
            }
            .padding(.horizontal, 24).padding(.vertical, 14).background(Color.bgCard)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(Color.bgPrimary)
    }
}
