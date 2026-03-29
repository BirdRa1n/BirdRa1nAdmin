// Sources/BirdRa1nAdmin/Views/Apps/AppsListView.swift
import SwiftUI
import Supabase

struct AppsListView: View {
    @Binding var toast: ToastMessage?
    @State private var apps: [StoreApp] = []
    @State private var isLoading = true
    @State private var editingApp: StoreApp? = nil
    @State private var isCreatingNew = false
    @State private var deleteTarget: StoreApp? = nil
    @State private var showDelete = false
    @State private var sourceUrlCopied = false

    private var sourceUrl: String { "https://birdra1n.vercel.app/api/altstore/source.json" }
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Apps", subtitle: "// store.apps — AltStore Source") {
                isCreatingNew = true
            }
            SectionDivider()

            HStack(spacing: 12) {
                Image(systemName: "iphone").foregroundColor(.cyanNeon).font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALTSTORE SOURCE URL").monoLabel(size: 9).foregroundColor(.cyanNeon.opacity(0.7))
                    Text(sourceUrl).font(.system(size: 11, design: .monospaced)).foregroundColor(.cyanNeon).lineLimit(1)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(sourceUrl, forType: .string)
                    sourceUrlCopied = true
                    Task { try? await Task.sleep(nanoseconds: 2_000_000_000); sourceUrlCopied = false }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sourceUrlCopied ? "checkmark" : "doc.on.doc").font(.system(size: 11))
                        Text(sourceUrlCopied ? "COPIADO!" : "COPIAR").font(.system(size: 10, design: .monospaced))
                    }
                }
                .buttonStyle(.plain).foregroundColor(.cyanNeon)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.cyanNeon.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.cyanNeon.opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(Color.cyanNeon.opacity(0.04))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)

            if isLoading {
                ProgressView().padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if apps.isEmpty {
                EmptyStateView(icon: "iphone", title: "// Nenhum app ainda",
                               subtitle: "Adicione seu primeiro app para o AltStore")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(apps) { app in
                            AppCard(app: app) { editingApp = app } onDelete: {
                                deleteTarget = app; showDelete = true
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color.bgPrimary)
        .sheet(isPresented: $isCreatingNew) {
            AppEditorView(app: StoreApp.empty(), isNew: true) { saved in
                apps.insert(saved, at: 0)
                toast = .init(type: .success, message: "App criado!")
            }
        }
        .sheet(item: $editingApp) { app in
            AppEditorView(app: app, isNew: false) { saved in
                if let idx = apps.firstIndex(where: { $0.id == saved.id }) { apps[idx] = saved }
                toast = .init(type: .success, message: "App salvo!")
            }
        }
        .confirmationDialog("Deletar App", isPresented: $showDelete, presenting: deleteTarget) { target in
            Button("Deletar", role: .destructive) { deleteApp(target) }
            Button("Cancelar", role: .cancel) {}
        } message: { target in
            Text("Deletar \"\(target.name)\"? Todas as versões serão removidas.")
        }
        .task { await loadApps() }
    }

    private func loadApps() async {
        isLoading = true
        apps = (try? await supabase.schema("store").from("apps")
            .select("id,name,bundle_id,developer,subtitle,icon_url,status,is_beta,featured,min_ios_version,category,created_at")
            .order("created_at", ascending: false).execute().value) ?? []
        isLoading = false
    }

    private func deleteApp(_ app: StoreApp) {
        Task {
            try? await supabase.schema("store").from("apps").delete().eq("id", value: app.id).execute()
            apps.removeAll { $0.id == app.id }
            toast = .init(type: .success, message: "App deletado")
        }
    }
}

// MARK: - App Card
struct AppCard: View {
    let app: StoreApp
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if let icon = app.iconUrl, let url = URL(string: icon) {
                        AsyncImage(url: url) { img in img.resizable().aspectRatio(contentMode: .fill) }
                        placeholder: { Color.bgCardAlt }
                    } else {
                        ZStack {
                            Color.cyanNeon.opacity(0.1)
                            Image(systemName: "iphone").foregroundColor(.cyanNeon).font(.system(size: 18))
                        }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(app.name).font(.system(size: 13, weight: .bold)).foregroundColor(.textPrimary).lineLimit(1)
                        if app.status != nil { StatusBadge(status: app.status!) }
                    }
                    Text(app.bundleId).font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted).lineLimit(1)
                    if app.isBeta == true { TagChip(text: "BETA", color: .warning) }
                }
                Spacer()
            }

            if let subtitle = app.subtitle ?? app.description, !subtitle.isEmpty {
                Text(subtitle).font(.system(size: 11)).foregroundColor(.textMuted).lineLimit(2)
            }

            HStack {
                Text("iOS \(app.minIosVersion ?? "15")+")
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted.opacity(0.5))
                Spacer()
                if hovered {
                    Button(action: onEdit) { Image(systemName: "pencil").font(.system(size: 11)) }
                        .buttonStyle(.plain).foregroundColor(.neon)
                    Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 11)) }
                        .buttonStyle(.plain).foregroundColor(.danger)
                }
            }
        }
        .padding(14).background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(hovered ? Color.neon.opacity(0.5) : Color.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovered)
    }
}

// MARK: - App Editor
struct AppEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var app: StoreApp
    let isNew: Bool
    let onSave: (StoreApp) -> Void
    @State private var _toast: ToastMessage? = nil
    @State private var isSaving = false

    let categories = ["utilities","social","productivity","developer-tools","entertainment",
                      "games","education","finance","health-fitness","lifestyle",
                      "music","photo-video","shopping","sports","travel","weather"]

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(
                title: isNew ? "Novo App" : "Editar: \(app.name)",
                subtitle: "// store.apps",
                onBack: { dismiss() },
                onSave: { Task { await save() } },
                isSaving: isSaving
            )
            SectionDivider()

            ScrollView {
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 16) {
                        AdminCard {
                            VStack(spacing: 14) {
                                HStack(spacing: 14) {
                                    TerminalField(label: "Nome", text: $app.name, placeholder: "MyApp", required: true)
                                    TerminalField(label: "Bundle ID", text: $app.bundleId, placeholder: "com.birdra1n.myapp", required: true)
                                }
                                TerminalField(label: "Developer",
                                             text: Binding(get: { app.developer ?? "" }, set: { app.developer = $0 }),
                                             placeholder: "BirdRa1n")
                                TerminalField(label: "Subtítulo",
                                             text: Binding(get: { app.subtitle ?? "" }, set: { app.subtitle = $0 }),
                                             placeholder: "Uma linha sobre o app...")
                                TerminalEditor(label: "Descrição",
                                               text: Binding(get: { app.description ?? "" }, set: { app.description = $0 }),
                                               placeholder: "Descrição completa...", minHeight: 100)
                            }
                        }

                        if !isNew {
                            AdminCard {
                                AppVersionsView(appId: app.id, toast: $_toast)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        AdminCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PUBLICAÇÃO").monoLabel().foregroundColor(.textMuted)
                                StatusPicker(status: Binding(get: { app.status ?? "draft" }, set: { app.status = $0 }),
                                             options: ["draft", "published", "archived"])
                                ToggleRow(label: "Em Destaque", description: "Mostrar na seção featured",
                                          isOn: Binding(get: { app.featured ?? false }, set: { app.featured = $0 }))
                                ToggleRow(label: "Beta", description: "Marcar como versão beta",
                                          isOn: Binding(get: { app.isBeta ?? false }, set: { app.isBeta = $0 }))
                            }
                        }

                        AdminCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ÍCONE").monoLabel().foregroundColor(.textMuted)
                                TerminalField(label: "URL do Ícone",
                                             text: Binding(get: { app.iconUrl ?? "" }, set: { app.iconUrl = $0 }),
                                             placeholder: "https://...")
                                if let icon = app.iconUrl, !icon.isEmpty, let url = URL(string: icon) {
                                    AsyncImage(url: url) { img in img.resizable().aspectRatio(contentMode: .fill) }
                                    placeholder: { Color.bgCardAlt }
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
                                }
                            }
                        }

                        AdminCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DETALHES").monoLabel().foregroundColor(.textMuted)
                                FormField(label: "Categoria") {
                                    Picker("", selection: Binding(get: { app.category ?? "utilities" }, set: { app.category = $0 })) {
                                        ForEach(categories, id: \.self) { c in Text(c).tag(c) }
                                    }
                                    .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                                }
                                TerminalField(label: "iOS Mínimo",
                                             text: Binding(get: { app.minIosVersion ?? "15.0" }, set: { app.minIosVersion = $0 }),
                                             placeholder: "15.0")
                            }
                        }
                    }
                    .frame(width: 240)
                }
                .padding(20)
            }
        }
        .background(Color.bgPrimary)
        .frame(minWidth: 800, minHeight: 560)
    }

    private func save() async {
        isSaving = true
        do {
            if isNew {
                let saved: StoreApp = try await supabase.schema("store").from("apps")
                    .insert(app).select().single().execute().value
                onSave(saved)
            } else {
                try await supabase.schema("store").from("apps")
                    .update(app).eq("id", value: app.id).execute()
                onSave(app)
            }
            dismiss()
        } catch {}
        isSaving = false
    }
}
