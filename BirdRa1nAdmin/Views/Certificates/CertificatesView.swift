// BirdRa1nAdmin/Views/Certificates/CertificatesView.swift
import SwiftUI
import Supabase

struct CertificatesView: View {
    @Binding var toast: ToastMessage?
    @State private var certs: [Certificate] = []
    @State private var orgs: [Organization] = []
    @State private var isLoading = true
    @State private var editingCert: Certificate?
    @State private var isNew = false
    @State private var showEditor = false
    @State private var deleteTarget: Certificate?
    @State private var showDelete = false

    var body: some View {
        Group {
            if isLoading {
                List { ForEach(0..<6) { _ in SkeletonRow() } }.listStyle(.inset)
            } else if certs.isEmpty {
                EmptyStateView(icon: "rosette", title: "Nenhum certificado",
                               subtitle: "Adicione seus certificados e cursos")
            } else {
                ScrollView {
                    // adaptive: cada card tem no mínimo 240pt, cresce para preencher a linha
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 240), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(certs) { cert in
                            CertCard(
                                cert: cert,
                                org: orgs.first { $0.id == cert.organizationId }
                            ) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Certificados")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Cria um certificado vazio e abre o editor
                    editingCert = Certificate.empty()
                    isNew = true
                    showEditor = true
                } label: {
                    Label("Novo Certificado", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let cert = editingCert {
                CertEditorView(cert: cert, orgs: orgs, isNew: isNew) { saved in
                    if isNew {
                        certs.insert(saved, at: 0)
                    } else if let i = certs.firstIndex(where: { $0.id == saved.id }) {
                        certs[i] = saved
                    }
                    toast = .init(type: .success, message: isNew ? "Certificado criado!" : "Certificado salvo!")
                }
            }
        }
        .confirmationDialog("Deletar Certificado?", isPresented: $showDelete, presenting: deleteTarget) { t in
            Button("Deletar \"\(t.title)\"", role: .destructive) { deleteCert(t) }
        } message: { _ in
            Text("Esta ação não pode ser desfeita.")
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        async let c: [Certificate] = (try? await supabase
            .schema(DB.portfolio).from("certificates")
            .select("id, organization_id, title, emission, url, skills, created_at")
            .order("emission", ascending: false)
            .execute().value) ?? []
        async let o: [Organization] = (try? await supabase
            .schema(DB.portfolio).from("organizations")
            .select("id, name, logo, email, phone, site, created_at")
            .execute().value) ?? []
        (certs, orgs) = await (c, o)
        isLoading = false
    }

    private func deleteCert(_ cert: Certificate) {
        Task {
            try? await supabase
                .schema(DB.portfolio).from("certificates")
                .delete().eq("id", value: cert.id).execute()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header: logo + título + menu
            HStack(alignment: .top, spacing: 10) {
                // Logo da organização
                AsyncImage(url: URL(string: org?.logo ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "building.2")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 36, height: 36)
                .background(.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(cert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(org?.name ?? "Organização")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                // Menu de ações com espaço adequado
                Menu {
                    Button("Editar", systemImage: "pencil", action: onEdit)
                    Divider()
                    Button("Deletar", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            // Data de emissão
            if let emission = cert.emission {
                Label(formatEmission(emission), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Skills — empurra o conteúdo para cima com Spacer
            Spacer(minLength: 0)

            if !cert.skills.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(cert.skills.prefix(6), id: \.self) { skill in
                        TagChip(text: skill)
                    }
                    if cert.skills.count > 6 {
                        Text("+\(cert.skills.count - 6)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        // frame com minHeight garante altura uniforme nos cards com pouco conteúdo
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(count: 2) { onEdit() }
    }

    private func formatEmission(_ s: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: s) {
            f.dateFormat = "MMMM 'de' yyyy"
            return f.string(from: d)
        }
        return s
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
        NavigationStack {
            Form {
                Section("Informações") {
                    AppTextField(label: "Título", text: $cert.title,
                                 placeholder: "AWS Cloud Practitioner", required: true)

                    FieldRow(label: "Organização") {
                        Picker("Organização", selection: Binding(
                            get: { cert.organizationId ?? "" },
                            set: { cert.organizationId = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Selecione...").tag("")
                            ForEach(orgs) { o in Text(o.name).tag(o.id) }
                        }
                        .labelsHidden()
                    }

                    AppTextField(label: "Data de Emissão",
                                 text: Binding(
                                    get: { cert.emission ?? "" },
                                    set: { cert.emission = $0.isEmpty ? nil : $0 }),
                                 placeholder: "YYYY-MM-DD",
                                 hint: "Ex: 2024-03-15")

                    AppTextField(label: "URL do Certificado",
                                 text: Binding(
                                    get: { cert.url ?? "" },
                                    set: { cert.url = $0.isEmpty ? nil : $0 }),
                                 placeholder: "https://...")
                }

                Section("Skills") {
                    HStack(spacing: 8) {
                        TextField("React, TypeScript...", text: $skillInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addSkills() }
                        Button("Adicionar", action: addSkills)
                            .disabled(skillInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !cert.skills.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(cert.skills, id: \.self) { skill in
                                HStack(spacing: 4) {
                                    TagChip(text: skill)
                                    Button {
                                        cert.skills.removeAll { $0 == skill }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNew ? "Novo Certificado" : "Editar Certificado")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView().controlSize(.small) }
                        else { Text("Salvar") }
                    }
                    .disabled(isSaving || cert.title.isEmpty)
                }
            }
            .frame(minWidth: 480, minHeight: 400)
        }
    }

    private func addSkills() {
        skillInput.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !cert.skills.contains($0) }
            .forEach { cert.skills.append($0) }
        skillInput = ""
    }

    private func save() async {
        isSaving = true
        do {
            let payload = CertificateInsert(from: cert)
            if isNew {
                let saved: Certificate = try await supabase
                    .schema(DB.portfolio).from("certificates")
                    .insert(payload).select().single().execute().value
                onSave(saved)
            } else {
                try await supabase
                    .schema(DB.portfolio).from("certificates")
                    .update(payload).eq("id", value: cert.id).execute()
                onSave(cert)
            }
            dismiss()
        } catch {}
        isSaving = false
    }
}
