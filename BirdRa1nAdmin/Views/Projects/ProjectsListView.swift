// Sources/BirdRa1nAdmin/Views/Projects/ProjectsListView.swift
import SwiftUI
import Supabase

struct ProjectsListView: View {
    @Binding var toast: ToastMessage?
    @State private var projects: [Project] = []
    @State private var isLoading = true
    @State private var editingProject: Project? = nil
    @State private var isCreatingNew = false
    @State private var deleteTarget: Project? = nil
    @State private var showDelete = false

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Projetos", subtitle: "// portfolio.projects") { isCreatingNew = true }
            SectionDivider()

            if isLoading {
                LoadingTable()
            } else if projects.isEmpty {
                EmptyStateView(icon: "folder", title: "// Nenhum projeto encontrado", subtitle: "Clique em NOVO para começar")
            } else {
                TableHeader(columns: [("Título", 0.4), ("Status", 0.12), ("Views", 0.12), ("Data", 0.16), ("Ações", 0.1)])
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(projects) { project in
                            ProjectRow(project: project) { editingProject = project } onDelete: {
                                deleteTarget = project; showDelete = true
                            }
                        }
                    }
                }
            }
        }
        .background(Color.bgPrimary)
        .sheet(isPresented: $isCreatingNew) {
            ProjectEditorView(project: Project.empty(), isNew: true) { saved in
                projects.insert(saved, at: 0)
                toast = .init(type: .success, message: "Projeto criado!")
            }
        }
        .sheet(item: $editingProject) { project in
            ProjectEditorView(project: project, isNew: false) { saved in
                if let idx = projects.firstIndex(where: { $0.id == saved.id }) { projects[idx] = saved }
                toast = .init(type: .success, message: "Projeto salvo!")
            }
        }
        .confirmationDialog("Deletar Projeto", isPresented: $showDelete, presenting: deleteTarget) { target in
            Button("Deletar", role: .destructive) { deleteProject(target) }
            Button("Cancelar", role: .cancel) {}
        } message: { target in Text("Tem certeza que deseja deletar \"\(target.title)\"?") }
        .task { await loadProjects() }
    }

    private func loadProjects() async {
        isLoading = true
        projects = (try? await supabase.schema("portfolio").from("projects")
            .select("id,title,slug,status,views_count,thumbnail_url,created_at")
            .order("created_at", ascending: false).execute().value) ?? []
        isLoading = false
    }

    private func deleteProject(_ project: Project) {
        Task {
            do {
                try await supabase.schema("portfolio").from("projects").delete().eq("id", value: project.id).execute()
                projects.removeAll { $0.id == project.id }
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
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: project.thumbnailUrl ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.bgCardAlt.overlay(Text("NO").font(.system(size: 8, design: .monospaced)).foregroundColor(.neon))
                }
                .frame(width: 36, height: 36).clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title).font(.system(size: 12, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(1)
                    Text("/\(project.slug)").font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let status = project.status { StatusBadge(status: status) }
            Spacer()
            Text("\(project.viewsCount ?? 0)").font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted).frame(width: 70, alignment: .leading)
            Text(formatDate(project.createdAt)).font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted).frame(width: 100, alignment: .leading)
            HStack(spacing: 8) {
                if hovered {
                    Button(action: onEdit) { Image(systemName: "pencil").font(.system(size: 11)) }
                        .buttonStyle(.plain).foregroundColor(.neon.opacity(0.7))
                    Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 11)) }
                        .buttonStyle(.plain).foregroundColor(.danger.opacity(0.7))
                }
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(hovered ? Color.bgCardAlt : Color.bgCard)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovered)
        .contentShape(Rectangle()).onTapGesture(count: 2) { onEdit() }
    }
}

// MARK: - Project Editor
struct ProjectEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var project: Project
    let isNew: Bool
    let onSave: (Project) -> Void

    @State private var isSaving = false
    @State private var techInput = ""
    @State private var categories: [Category] = []

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(
                title: isNew ? "Novo Projeto" : "Editar Projeto",
                subtitle: isNew ? "// portfolio.projects.insert" : "// portfolio.projects.update",
                onBack: { dismiss() },
                onSave: { Task { await save() } },
                isSaving: isSaving
            )
            SectionDivider()

            ScrollView {
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 16) {
                        AdminCard {
                            VStack(spacing: 16) {
                                TerminalField(label: "Título", text: $project.title, placeholder: "Meu Projeto", required: true)
                                    .onChange(of: project.title) { _, new in if isNew { project.slug = slugify(new) } }
                                TerminalField(label: "Slug",
                                             text: Binding(get: { project.slug }, set: { project.slug = slugify($0) }),
                                             placeholder: "meu-projeto", required: true, hint: "// URL: /projects/{slug}")
                                TerminalEditor(label: "Descrição",
                                               text: Binding(get: { project.description ?? "" }, set: { project.description = $0 }),
                                               placeholder: "Uma breve descrição...", minHeight: 80)
                            }
                        }
                        AdminCard {
                            TerminalEditor(label: "Conteúdo (Markdown)",
                                           text: Binding(get: { project.content ?? "" }, set: { project.content = $0 }),
                                           placeholder: "# Título\n\nDescreva o projeto...", minHeight: 280)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        AdminCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("PUBLICAÇÃO").monoLabel().foregroundColor(.textMuted)
                                StatusPicker(status: Binding(get: { project.status ?? "draft" }, set: { project.status = $0 }),
                                             options: ["draft", "published", "archived"])
                                ToggleRow(label: "Destaque", description: "Mostrar na seção de destaque",
                                          isOn: Binding(get: { project.featured ?? false }, set: { project.featured = $0 }))
                            }
                        }
                        AdminCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MÍDIA").monoLabel().foregroundColor(.textMuted)
                                TerminalField(label: "Thumbnail URL",
                                             text: Binding(get: { project.thumbnailUrl ?? "" }, set: { project.thumbnailUrl = $0 }),
                                             placeholder: "https://...")
                                if let url = project.thumbnailUrl, !url.isEmpty, let u = URL(string: url) {
                                    AsyncImage(url: u) { img in img.resizable().aspectRatio(contentMode: .fill) }
                                    placeholder: { Color.bgCardAlt }
                                    .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
                                }
                            }
                        }
                        AdminCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("LINKS").monoLabel().foregroundColor(.textMuted)
                                TerminalField(label: "Demo URL",
                                             text: Binding(get: { project.demoUrl ?? "" }, set: { project.demoUrl = $0 }),
                                             placeholder: "https://...")
                                TerminalField(label: "Repositório",
                                             text: Binding(get: { project.repoUrl ?? "" }, set: { project.repoUrl = $0 }),
                                             placeholder: "https://github.com/...")
                            }
                        }
                        AdminCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TECH STACK").monoLabel().foregroundColor(.textMuted)
                                HStack(spacing: 8) {
                                    TextField("React, TypeScript...", text: $techInput)
                                        .textFieldStyle(.plain).font(.system(size: 11, design: .monospaced)).foregroundColor(.textPrimary)
                                        .padding(8).background(Color.bgCardAlt)
                                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .onSubmit { addTech() }
                                    Button { addTech() } label: { Image(systemName: "plus") }
                                        .buttonStyle(NeonButtonStyle(variant: .outline))
                                }
                                FlowLayout(spacing: 6) {
                                    ForEach(project.techStack ?? [], id: \.self) { tech in
                                        HStack(spacing: 4) {
                                            TagChip(text: tech)
                                            Button { project.techStack?.removeAll { $0 == tech } } label: {
                                                Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(.textMuted)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 240)
                }
                .padding(20)
            }
        }
        .background(Color.bgPrimary)
        .frame(minWidth: 800, minHeight: 600)
        .task { await loadCategories() }
    }

    private func addTech() {
        let items = techInput.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        for item in items where !(project.techStack?.contains(item) ?? false) { project.techStack?.append(item) }
        techInput = ""
    }

    private func loadCategories() async {
        categories = (try? await supabase.schema("portfolio").from("categories").select().execute().value) ?? []
    }

    private func save() async {
        isSaving = true
        do {
            if isNew {
                let saved: Project = try await supabase.schema("portfolio").from("projects")
                    .insert(project).select().single().execute().value
                onSave(saved)
            } else {
                try await supabase.schema("portfolio").from("projects").update(project).eq("id", value: project.id).execute()
                onSave(project)
            }
            dismiss()
        } catch {}
        isSaving = false
    }
}

// MARK: - Helpers
func slugify(_ text: String) -> String {
    text.lowercased()
        .applyingTransform(.toLatin, reverse: false)?
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
        .joined(separator: "-") ?? text
}

func formatDate(_ iso: String?) -> String {
    guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return "-" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateFormat = "dd/MM/yyyy"
    return f.string(from: date)
}

// MARK: - Table header
struct TableHeader: View {
    let columns: [(String, CGFloat)]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns, id: \.0) { col in
                Text(col.0.uppercased()).monoLabel(size: 10).foregroundColor(.textMuted)
                    .frame(maxWidth: col.1 == 0 ? .infinity : nil, alignment: .leading)
                    .frame(width: col.1 == 0 ? nil : col.1 * 500)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.bgCardAlt)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)
    }
}

// MARK: - Loading table
struct LoadingTable: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<6) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.bgCard).frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.bgCard).frame(width: 140, height: 10)
                        RoundedRectangle(cornerRadius: 2).fill(Color.bgCard).frame(width: 80, height: 8)
                    }
                    Spacer()
                }
                .shimmer().padding(.horizontal, 20).padding(.vertical, 14)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.border), alignment: .bottom)
            }
        }
    }
}

// MARK: - Flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0; var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { y += rowHeight + spacing; x = 0; rowHeight = 0 }
            rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
        height = y + rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { y += rowHeight + spacing; x = bounds.minX; rowHeight = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
    }
}
