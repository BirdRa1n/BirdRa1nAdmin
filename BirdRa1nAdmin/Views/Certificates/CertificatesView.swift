// Sources/BirdRa1nAdmin/Views/Certificates/CertificatesView.swift
import SwiftUI
import Supabase

struct CertificatesView: View {
    @Binding var toast: ToastMessage?
    @State private var certs: [Certificate] = []
    @State private var orgs: [Organization] = []
    @State private var isLoading = true
    @State private var editingCert: Certificate? = nil
    @State private var showEditor = false
    @State private var isNew = false
    @State private var deleteTarget: Certificate? = nil
    @State private var showDelete = false

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Certificados", subtitle: "// portfolio.certificates", action: {
                editingCert = Certificate.empty()
                isNew = true
                showEditor = true
            })
            SectionDivider()

            if isLoading {
                ProgressView().padding(40)
            } else if certs.isEmpty {
                EmptyStateView(icon: "rosette", title: "// Nenhum certificado ainda")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(certs) { cert in
                            CertCard(cert: cert, org: orgs.first(where: { $0.id == cert.organizationId })) {
                                editingCert = cert; isNew = false; showEditor = true
                            } onDelete: {
                                deleteTarget = cert; showDelete = true
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color.bgPrimary)
        .sheet(isPresented: $showEditor) {
            if let cert = editingCert {
                CertEditorView(cert: cert, orgs: orgs, isNew: isNew) { saved in
                    if isNew { certs.insert(saved, at: 0) }
                    else if let idx = certs.firstIndex(where: { $0.id == saved.id }) { certs[idx] = saved }
                    toast = .init(type: .success, message: isNew ? "Certificado criado!" : "Certificado salvo!")
                }
            }
        }
        .confirmationDialog("Deletar Certificado", isPresented: $showDelete, presenting: deleteTarget) { target in
            Button("Deletar", role: .destructive) { deleteCert(target) }
            Button("Cancelar", role: .cancel) {}
        } message: { _ in Text("Esta ação não pode ser desfeita.") }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        async let c: [Certificate] = (try? await supabase.schema("portfolio").from("certificates")
            .select("id,title,organization_id,emission,url,skills")
            .order("emission", ascending: false).execute().value) ?? []
        async let o: [Organization] = (try? await supabase.schema("portfolio").from("organizations")
            .select().execute().value) ?? []
        let (certs2, orgs2) = await (c, o)
        certs = certs2; orgs = orgs2
        isLoading = false
    }

    private func deleteCert(_ cert: Certificate) {
        Task {
            try? await supabase.schema("portfolio").from("certificates").delete().eq("id", value: cert.id).execute()
            certs.removeAll { $0.id == cert.id }
            toast = .init(type: .success, message: "Certificado removido")
        }
    }
}

// MARK: - Cert Card
struct CertCard: View {
    let cert: Certificate
    let org: Organization?
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Group {
                    if let logo = org?.logo, let url = URL(string: logo) {
                        AsyncImage(url: url) { img in img.resizable().aspectRatio(contentMode: .fit) }
                        placeholder: { Color.bgCardAlt }
                    } else {
                        ZStack {
                            Color.neon.opacity(0.08)
                            Image(systemName: "rosette").foregroundColor(.neon).font(.system(size: 14))
                        }
                    }
                }
                .frame(width: 38, height: 38).clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(cert.title).font(.system(size: 12, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(2)
                    Text(org?.name ?? "").font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted).lineLimit(1)
                }
                Spacer()
                if hovered {
                    VStack(spacing: 6) {
                        Button(action: onEdit) { Image(systemName: "pencil").font(.system(size: 10)) }
                            .buttonStyle(.plain).foregroundColor(.neon)
                        Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 10)) }
                            .buttonStyle(.plain).foregroundColor(.danger)
                    }
                }
            }

            if let emission = cert.emission {
                Text(formatEmission(emission)).font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted.opacity(0.5))
            }

            if let skills = cert.skills, !skills.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(skills.prefix(4), id: \.self) { TagChip(text: $0) }
                    if skills.count > 4 {
                        Text("+\(skills.count - 4)").font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
                    }
                }
            }
        }
        .padding(14).background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(hovered ? Color.neon.opacity(0.5) : Color.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovered)
    }

    private func formatEmission(_ str: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR"); f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: str) { f.dateFormat = "MMMM 'de' yyyy"; return f.string(from: d) }
        return str
    }
}

// MARK: - Cert Editor
struct CertEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var cert: Certificate
    let orgs: [Organization]
    let isNew: Bool
    let onSave: (Certificate) -> Void

    @State private var isSaving = false
    @State private var skillInput = ""

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(
                title: isNew ? "Novo Certificado" : "Editar Certificado",
                onBack: { dismiss() },
                onSave: { Task { await save() } },
                isSaving: isSaving
            )
            SectionDivider()

            ScrollView {
                VStack(spacing: 16) {
                    AdminCard {
                        VStack(spacing: 14) {
                            TerminalField(label: "Título", text: $cert.title, placeholder: "AWS Cloud Practitioner", required: true)
                            FormField(label: "Organização") {
                                Picker("", selection: Binding(get: { cert.organizationId ?? "" }, set: { cert.organizationId = $0 })) {
                                    Text("Selecione...").tag("")
                                    ForEach(orgs) { org in Text(org.name).tag(org.id) }
                                }
                                .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            FormField(label: "Data de Emissão") {
                                TextField("YYYY-MM-DD", text: Binding(get: { cert.emission ?? "" }, set: { cert.emission = $0 }))
                                    .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced)).foregroundColor(.textPrimary)
                                    .padding(10).background(Color.bgCardAlt)
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            TerminalField(label: "URL do Certificado",
                                         text: Binding(get: { cert.url ?? "" }, set: { cert.url = $0 }),
                                         placeholder: "https://...")
                        }
                    }

                    AdminCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SKILLS").monoLabel().foregroundColor(.textMuted)
                            HStack(spacing: 8) {
                                TextField("React, TypeScript...", text: $skillInput)
                                    .textFieldStyle(.plain).font(.system(size: 11, design: .monospaced)).foregroundColor(.textPrimary)
                                    .padding(8).background(Color.bgCardAlt)
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                    .onSubmit { addSkills() }
                                Button { addSkills() } label: { Image(systemName: "plus") }
                                    .buttonStyle(NeonButtonStyle(variant: .outline))
                            }
                            FlowLayout(spacing: 6) {
                                ForEach(cert.skills ?? [], id: \.self) { skill in
                                    HStack(spacing: 4) {
                                        TagChip(text: skill)
                                        Button { cert.skills?.removeAll { $0 == skill } } label: {
                                            Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(.textMuted)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Spacer()
                        Button("Cancelar") { dismiss() }.buttonStyle(NeonButtonStyle(variant: .outline))
                        Button { Task { await save() } } label: {
                            HStack(spacing: 6) {
                                if isSaving { NeonSpinner() }
                                Text(isSaving ? "SALVANDO..." : "SALVAR")
                            }
                        }
                        .buttonStyle(NeonButtonStyle(variant: .primary)).disabled(isSaving)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.bgPrimary)
        .frame(minWidth: 500, minHeight: 480)
    }

    private func addSkills() {
        let items = skillInput.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
        for item in items where !(cert.skills?.contains(item) ?? false) {
            if cert.skills == nil { cert.skills = [] }
            cert.skills?.append(item)
        }
        skillInput = ""
    }

    private func save() async {
        isSaving = true
        struct CertPayload: Encodable {
            var title: String; var organizationId: String?
            var emission: String?; var url: String?; var skills: [String]?
        }
        let payload = CertPayload(
            title: cert.title,
            organizationId: cert.organizationId.flatMap { $0.isEmpty ? nil : $0 },
            emission: cert.emission, url: cert.url, skills: cert.skills
        )
        do {
            if isNew {
                let saved: Certificate = try await supabase.schema("portfolio").from("certificates")
                    .insert(payload).select().single().execute().value
                onSave(saved)
            } else {
                try await supabase.schema("portfolio").from("certificates")
                    .update(payload).eq("id", value: cert.id).execute()
                onSave(cert)
            }
            dismiss()
        } catch {}
        isSaving = false
    }
}
