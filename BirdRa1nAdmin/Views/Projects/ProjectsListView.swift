// BirdRa1nAdmin/Views/Projects/ProjectsListView.swift
import SwiftUI
import Supabase

struct ProjectsListView: View {
    @Binding var toast: ToastMessage?
    @State private var projects: [Project] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var editingProject: Project?
    @State private var isCreatingNew = false
    @State private var deleteTarget: Project?
    @State private var showDelete = false
    @State private var searchText = ""

    private var filtered: [Project] {
        guard !searchText.isEmpty else { return projects }
        return projects.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.slug.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                List { ForEach(0..<8) { _ in SkeletonRow() } }
                    .listStyle(.inset)
            } else if let err = loadError {
                // Mostra o erro real para diagnóstico
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle).foregroundStyle(.orange)
                    Text("Erro ao carregar projetos")
                        .font(.headline)
                    Text(err)
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Tentar novamente") {
                        Task { await loadProjects() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filtered.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: searchText.isEmpty ? "Nenhum projeto" : "Sem resultados",
                    subtitle: searchText.isEmpty ? "Crie seu primeiro projeto clicando no +" : nil
                )
            } else {
                List {
                    ForEach(filtered) { project in
                        ProjectRow(project: project) { editingProject = project }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTarget = project; showDelete = true
                                } label: { Label("Deletar", systemImage: "trash") }
                            }
                    }
                }
                .listStyle(.inset)
                .alternatingRowBackgrounds()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Projetos")
        .searchable(text: $searchText, prompt: "Buscar projetos...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreatingNew = true } label: {
                    Label("Novo Projeto", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await loadProjects() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Recarregar")
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $isCreatingNew) {
            ProjectEditorView(project: Project.empty(), isNew: true) { saved in
                projects.insert(saved, at: 0)
                toast = .init(type: .success, message: "Projeto criado!")
            }
        }
        .sheet(item: $editingProject) { p in
            ProjectEditorView(project: p, isNew: false) { saved in
                if let i = projects.firstIndex(where: { $0.id == saved.id }) { projects[i] = saved }
                toast = .init(type: .success, message: "Projeto salvo!")
            }
        }
        .confirmationDialog("Deletar Projeto?", isPresented: $showDelete, presenting: deleteTarget) { t in
            Button("Deletar \"\(t.title)\"", role: .destructive) { deleteProject(t) }
        }
        .task { await loadProjects() }
    }

    private func loadProjects() async {
        isLoading = true
        loadError = nil
        do {
            projects = try await supabase
                .schema(DB.portfolio)
                .from("projects")
                .select("id, title, slug, status, views_count, thumbnail_url, created_at, updated_at")
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteProject(_ p: Project) {
        Task {
            do {
                try await supabase
                    .schema(DB.portfolio).from("projects")
                    .delete().eq("id", value: p.id).execute()
                projects.removeAll { $0.id == p.id }
                toast = .init(type: .success, message: "Projeto deletado")
            } catch {
                toast = .init(type: .error, message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: project.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.secondary.opacity(0.12))
                            .overlay(
                                Image(systemName: "folder")
                                    .foregroundStyle(.tertiary)
                            )
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(.subheadline).fontWeight(.medium)
                    Text("/\(project.slug)")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye").foregroundStyle(.secondary)
                        Text("\(project.viewsCount)").foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    StatusBadge(status: project.status)

                    Text(formatDate(project.createdAt))
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Project Editor
struct ProjectEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var project: Project
    let isNew: Bool
    let onSave: (Project) -> Void

    @State private var isSaving = false
    @State private var saveError: String?
    @State private var techInput = ""
    @State private var categories: [Category] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Informações Básicas") {
                    AppTextField(label: "Título", text: $project.title,
                                 placeholder: "Meu Projeto", required: true)
                        .onChange(of: project.title) { _, v in
                            if isNew { project.slug = slugify(v) }
                        }
                    AppTextField(label: "Slug",
                                 text: Binding(get: { project.slug },
                                               set: { project.slug = slugify($0) }),
                                 placeholder: "meu-projeto", required: true,
                                 hint: "/projects/\(project.slug)")
                    AppTextEditor(label: "Descrição",
                                  text: Binding(get: { project.description ?? "" },
                                                set: { project.description = $0.isEmpty ? nil : $0 }),
                                  placeholder: "Descrição curta...", minHeight: 70)
                }

                Section("Conteúdo") {
                    AppTextEditor(label: "Conteúdo (Markdown)",
                                  text: Binding(get: { project.content ?? "" },
                                                set: { project.content = $0.isEmpty ? nil : $0 }),
                                  placeholder: "# Título\n\nDescreva o projeto...", minHeight: 180)
                }

                Section("Publicação") {
                    AppStatusPicker(status: $project.status,
                                    options: ["draft", "published", "archived"])
                    AppToggle(label: "Em Destaque",
                               description: "Mostrar na seção de destaque",
                               isOn: $project.featured)
                }

                Section("Mídia & Links") {
                    AppTextField(label: "Thumbnail URL",
                                 text: Binding(get: { project.thumbnailUrl ?? "" },
                                               set: { project.thumbnailUrl = $0.isEmpty ? nil : $0 }),
                                 placeholder: "https://...")
                    URLImagePreview(urlString: project.thumbnailUrl, height: 90)
                    AppTextField(label: "Demo URL",
                                 text: Binding(get: { project.demoUrl ?? "" },
                                               set: { project.demoUrl = $0.isEmpty ? nil : $0 }),
                                 placeholder: "https://")
                    AppTextField(label: "Repositório",
                                 text: Binding(get: { project.repoUrl ?? "" },
                                               set: { project.repoUrl = $0.isEmpty ? nil : $0 }),
                                 placeholder: "https://github.com/...")
                }

                Section("Tech Stack") {
                    HStack(spacing: 8) {
                        TextField("React, Swift...", text: $techInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addTech() }
                        Button("Adicionar", action: addTech)
                            .disabled(techInput.isEmpty)
                    }
                    if !project.techStack.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(project.techStack, id: \.self) { tech in
                                HStack(spacing: 4) {
                                    TagChip(text: tech)
                                    Button {
                                        project.techStack.removeAll { $0 == tech }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                if !categories.isEmpty {
                    Section("Categoria") {
                        Picker("Categoria", selection: Binding(
                            get: { project.categoryId ?? "" },
                            set: { project.categoryId = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Nenhuma").tag("")
                            ForEach(categories) { c in Text(c.name).tag(c.id) }
                        }
                    }
                }

                if let err = saveError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNew ? "Novo Projeto" : "Editar Projeto")
            .navigationSubtitle(isNew ? "" : project.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if isSaving { ProgressView().controlSize(.small) }
                        else { Text("Salvar") }
                    }
                    .disabled(isSaving || project.title.isEmpty || project.slug.isEmpty)
                }
            }
            .frame(minWidth: 600, minHeight: 500)
        }
        .task { await loadCategories() }
    }

    private func addTech() {
        techInput.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !project.techStack.contains($0) }
            .forEach { project.techStack.append($0) }
        techInput = ""
    }

    private func loadCategories() async {
        categories = (try? await supabase
            .schema(DB.portfolio).from("categories")
            .select("id, name, slug")
            .execute().value) ?? []
    }

    private func save() async {
        isSaving = true
        saveError = nil
        do {
            let payload = ProjectInsert(from: project)
            if isNew {
                let saved: Project = try await supabase
                    .schema(DB.portfolio).from("projects")
                    .insert(payload).select().single().execute().value
                onSave(saved)
            } else {
                try await supabase
                    .schema(DB.portfolio).from("projects")
                    .update(payload).eq("id", value: project.id).execute()
                onSave(project)
            }
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}
