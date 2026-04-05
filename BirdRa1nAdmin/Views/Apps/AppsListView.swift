// BirdRa1nAdmin/Views/Apps/AppsListView.swift
import SwiftUI
import Supabase

struct AppsListView: View {
    @Binding var toast: ToastMessage?
    @State private var apps: [StoreApp] = []
    @State private var isLoading = true
    @State private var editingApp: StoreApp?
    @State private var isCreatingNew = false
    @State private var deleteTarget: StoreApp?
    @State private var showDelete = false
    @State private var sourceUrlCopied = false

    private let sourceUrl = "https://birdra1n.vercel.app/api/altstore/source.json"

    var body: some View {
        VStack(spacing: 0) {
            // Banner AltStore source URL
            HStack(spacing: 10) {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(.tint)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AltStore Source URL")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                    Text(sourceUrl)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(sourceUrl, forType: .string)
                    sourceUrlCopied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        sourceUrlCopied = false
                    }
                } label: {
                    Label(
                        sourceUrlCopied ? "Copiado!" : "Copiar",
                        systemImage: sourceUrlCopied ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(sourceUrlCopied ? .green : .accentColor)
                .animation(.easeInOut(duration: 0.2), value: sourceUrlCopied)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            // Conteúdo principal
            Group {
                if isLoading {
                    List { ForEach(0..<6) { _ in SkeletonRow() } }.listStyle(.inset)
                } else if apps.isEmpty {
                    EmptyStateView(icon: "iphone", title: "Nenhum app",
                                   subtitle: "Adicione apps ao seu AltStore source")
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(apps) { app in
                                AppCardView(app: app) { editingApp = app } onDelete: {
                                    deleteTarget = app; showDelete = true
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Apps")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreatingNew = true } label: {
                    Label("Novo App", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingNew) {
            AppEditorView(app: StoreApp.empty(), isNew: true) { saved in
                apps.insert(saved, at: 0)
                toast = .init(type: .success, message: "App criado!")
            }
        }
        .sheet(item: $editingApp) { app in
            AppEditorView(app: app, isNew: false) { saved in
                if let i = apps.firstIndex(where: { $0.id == saved.id }) { apps[i] = saved }
                toast = .init(type: .success, message: "App salvo!")
            }
        }
        .confirmationDialog("Deletar App?", isPresented: $showDelete, presenting: deleteTarget) { t in
            Button("Deletar \"\(t.name)\"", role: .destructive) { deleteApp(t) }
        } message: { t in
            Text("Todas as versões de \"\(t.name)\" serão removidas.")
        }
        .task { await loadApps() }
    }

    private func loadApps() async {
        isLoading = true
        apps = (try? await supabase.schema(DB.store).from("apps")
            .select("id, name, bundle_id, developer, subtitle, description, icon_url, status, is_beta, featured, min_ios_version, category, created_at, updated_at")
            .order("created_at", ascending: false)
            .execute().value) ?? []
        isLoading = false
    }

    private func deleteApp(_ app: StoreApp) {
        Task {
            try? await supabase.schema(DB.store).from("app_versions")
                .delete().eq("app_id", value: app.id).execute()
            try? await supabase.schema(DB.store).from("apps")
                .delete().eq("id", value: app.id).execute()
            apps.removeAll { $0.id == app.id }
            toast = .init(type: .success, message: "App deletado")
        }
    }
}

// MARK: - App Card
struct AppCardView: View {
    let app: StoreApp
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header com ícone e nome
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: app.iconUrl ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.secondary.opacity(0.1))
                            Image(systemName: "iphone")
                                .foregroundStyle(.secondary).font(.title2)
                        }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(app.name)
                            .font(.subheadline).fontWeight(.semibold).lineLimit(1)
                        if app.isBeta {
                            TagChip(text: "BETA", color: .orange)
                        }
                    }
                    Text(app.bundleId)
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    StatusBadge(status: app.status)
                }

                Spacer()

                Menu {
                    Button("Editar", systemImage: "pencil", action: onEdit)
                    Divider()
                    Button("Deletar", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }

            // Subtítulo / descrição
            if let sub = app.subtitle ?? app.appDescription, !sub.isEmpty {
                Text(sub)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }

            // Footer
            HStack {
                Label("iOS \(app.minIosVersion)+", systemImage: "iphone")
                    .font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(app.category.capitalized)
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(count: 2) { onEdit() }
    }
}

// MARK: - App Editor
struct AppEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var app: StoreApp
    let isNew: Bool
    let onSave: (StoreApp) -> Void

    @State private var isSaving = false

    private let categories = [
        "utilities", "social", "productivity", "developer-tools", "entertainment",
        "games", "education", "finance", "health-fitness", "lifestyle",
        "music", "photo-video", "shopping", "sports", "travel", "weather"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Informações do App") {
                    AppTextField(label: "Nome", text: $app.name,
                                 placeholder: "MyApp", required: true)
                    AppTextField(label: "Bundle ID", text: $app.bundleId,
                                 placeholder: "com.birdra1n.myapp", required: true)
                    AppTextField(label: "Developer", text: $app.developer,
                                 placeholder: "BirdRa1n")
                    AppTextField(label: "Subtítulo",
                                 text: Binding(get: { app.subtitle ?? "" },
                                               set: { app.subtitle = $0.isEmpty ? nil : $0 }),
                                 placeholder: "Uma linha sobre o app...")
                    AppTextEditor(label: "Descrição",
                                  text: Binding(get: { app.appDescription ?? "" },
                                                set: { app.appDescription = $0.isEmpty ? nil : $0 }),
                                  placeholder: "Descrição completa do app...", minHeight: 80)
                }

                Section("Publicação") {
                    AppStatusPicker(status: $app.status, options: ["draft", "published", "archived"])
                    AppToggle(label: "Em Destaque",
                               description: "Exibir na seção featured do source",
                               isOn: $app.featured)
                    AppToggle(label: "Beta",
                               description: "Marcar como versão beta/experimental",
                               isOn: $app.isBeta)
                }

                Section("Ícone") {
                    AppTextField(label: "URL do Ícone",
                                 text: Binding(get: { app.iconUrl ?? "" },
                                               set: { app.iconUrl = $0.isEmpty ? nil : $0 }),
                                 placeholder: "https://...")
                    if let icon = app.iconUrl, !icon.isEmpty, let url = URL(string: icon) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }

                Section("Detalhes") {
                    FieldRow(label: "Categoria") {
                        Picker("Categoria", selection: $app.category) {
                            ForEach(categories, id: \.self) { c in
                                Text(c.capitalized.replacingOccurrences(of: "-", with: " ")).tag(c)
                            }
                        }
                        .labelsHidden()
                    }
                    AppTextField(label: "Versão mínima iOS",
                                 text: $app.minIosVersion,
                                 placeholder: "15.0")
                }

                // Versões (só no modo edição)
                if !isNew {
                    Section("Versões") {
                        AppVersionsInlineView(appId: app.id)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNew ? "Novo App" : "Editar App")
            .navigationSubtitle(isNew ? "" : app.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if isSaving { ProgressView().controlSize(.small) }
                        else { Text("Salvar") }
                    }
                    .disabled(isSaving || app.name.isEmpty || app.bundleId.isEmpty)
                }
            }
            .frame(minWidth: 560, minHeight: 500)
        }
    }

    private func save() async {
        isSaving = true
        do {
            let payload = StoreAppInsert(from: app)
            if isNew {
                let saved: StoreApp = try await supabase.schema(DB.store).from("apps")
                    .insert(payload).select().single().execute().value
                onSave(saved)
            } else {
                try await supabase.schema(DB.store).from("apps")
                    .update(payload).eq("id", value: app.id).execute()
                onSave(app)
            }
            dismiss()
        } catch {}
        isSaving = false
    }
}
