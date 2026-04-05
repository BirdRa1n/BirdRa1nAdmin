// BirdRa1nAdmin/Views/Blog/BlogListView.swift
import SwiftUI
import Supabase

struct BlogListView: View {
    @Binding var toast: ToastMessage?
    @State private var posts: [BlogPost] = []
    @State private var isLoading = true
    @State private var editingPost: BlogPost?
    @State private var isCreatingNew = false
    @State private var deleteTarget: BlogPost?
    @State private var showDelete = false
    @State private var searchText = ""

    private var filtered: [BlogPost] {
        guard !searchText.isEmpty else { return posts }
        return posts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.slug.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                List { ForEach(0..<8) { _ in SkeletonRow() } }.listStyle(.inset)
            } else if filtered.isEmpty {
                EmptyStateView(icon: "doc.richtext", title: "Nenhum post",
                               subtitle: searchText.isEmpty ? "Crie seu primeiro post clicando no +" : nil)
            } else {
                List {
                    ForEach(filtered) { post in
                        BlogPostRow(post: post) { editingPost = post }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTarget = post; showDelete = true
                                } label: { Label("Deletar", systemImage: "trash") }
                            }
                    }
                }
                .listStyle(.inset)
                .alternatingRowBackgrounds()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Blog")
        .searchable(text: $searchText, prompt: "Buscar posts...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreatingNew = true } label: {
                    Label("Novo Post", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingNew) {
            BlogEditorView(post: BlogPost.empty(), isNew: true) { saved in
                posts.insert(saved, at: 0); toast = .init(type: .success, message: "Post criado!")
            }
        }
        .sheet(item: $editingPost) { p in
            BlogEditorView(post: p, isNew: false) { saved in
                if let i = posts.firstIndex(where: { $0.id == saved.id }) { posts[i] = saved }
                toast = .init(type: .success, message: "Post salvo!")
            }
        }
        .confirmationDialog("Deletar Post?", isPresented: $showDelete, presenting: deleteTarget) { t in
            Button("Deletar \"\(t.title)\"", role: .destructive) { deletePost(t) }
        }
        .task { await loadPosts() }
    }

    private func loadPosts() async {
        isLoading = true
        posts = (try? await supabase.schema(DB.blog).from("posts")
            .select("id, title, slug, status, featured, views_count, cover_url, created_at, published_at")
            .order("created_at", ascending: false).execute().value) ?? []
        isLoading = false
    }

    private func deletePost(_ p: BlogPost) {
        Task {
            try? await supabase.schema(DB.blog).from("post_tags").delete().eq("post_id", value: p.id).execute()
            try? await supabase.schema(DB.blog).from("posts").delete().eq("id", value: p.id).execute()
            posts.removeAll { $0.id == p.id }
            toast = .init(type: .success, message: "Post deletado")
        }
    }
}

// MARK: - Blog Post Row
struct BlogPostRow: View {
    let post: BlogPost
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Cover thumbnail
                AsyncImage(url: URL(string: post.coverUrl ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 6).fill(.secondary.opacity(0.12))
                            .overlay(Image(systemName: "doc.richtext").foregroundStyle(.tertiary))
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(post.title).font(.subheadline).fontWeight(.medium)
                        if post.featured { Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow) }
                    }
                    Text("/blog/\(post.slug)").font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye").foregroundStyle(.secondary)
                        Text("\(post.viewsCount)").foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    StatusBadge(status: post.status)

                    Text(formatDate(post.createdAt)).font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Blog Editor
struct BlogEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var post: BlogPost
    let isNew: Bool
    let onSave: (BlogPost) -> Void

    @State private var isSaving = false
    @State private var allTags: [BlogTag] = []
    @State private var selectedTagIds: [String] = []
    @State private var newTagName = ""

    private var wordCount: Int { post.content?.split(separator: " ").count ?? 0 }
    private var readTime: Int { max(1, wordCount / 200) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Informações Básicas") {
                    AppTextField(label: "Título", text: $post.title,
                                 placeholder: "Título do post...", required: true)
                        .onChange(of: post.title) { _, v in if isNew { post.slug = slugify(v) } }
                    AppTextField(label: "Slug", text: $post.slug,
                                 placeholder: "titulo-do-post", required: true,
                                 hint: "/blog/\(post.slug)")
                    AppTextEditor(label: "Resumo (Excerpt)",
                                  text: Binding(get: { post.excerpt ?? "" },
                                                set: { post.excerpt = $0.isEmpty ? nil : $0 }),
                                  placeholder: "Breve resumo para SEO...", minHeight: 60)
                }

                Section {
                    AppTextEditor(label: "Conteúdo (Markdown)",
                                  text: Binding(get: { post.content ?? "" },
                                                set: { post.content = $0.isEmpty ? nil : $0 }),
                                  placeholder: "# Título\n\nEscreva o conteúdo...", minHeight: 280)
                } header: {
                    HStack {
                        Text("Conteúdo")
                        Spacer()
                        Text("~\(readTime) min · \(wordCount) palavras")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Publicação") {
                    AppStatusPicker(status: $post.status, options: ["draft", "published", "archived"])
                    AppToggle(label: "Post em Destaque",
                               description: "Exibir no topo do blog",
                               isOn: $post.featured)
                }

                Section("Capa") {
                    AppTextField(label: "URL da Imagem de Capa",
                                 text: Binding(get: { post.coverUrl ?? "" },
                                               set: { post.coverUrl = $0.isEmpty ? nil : $0 }),
                                 placeholder: "https://...")
                    URLImagePreview(urlString: post.coverUrl, height: 80)
                }

                Section("Tags") {
                    HStack(spacing: 8) {
                        TextField("Nova tag...", text: $newTagName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { Task { await createTag() } }
                        Button("Criar") { Task { await createTag() } }
                            .disabled(newTagName.isEmpty)
                    }
                    if !allTags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(allTags) { tag in
                                let sel = selectedTagIds.contains(tag.id)
                                Button {
                                    if sel { selectedTagIds.removeAll { $0 == tag.id } }
                                    else   { selectedTagIds.append(tag.id) }
                                } label: {
                                    TagChip(text: tag.name, color: sel ? .accentColor : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNew ? "Novo Post" : "Editar Post")
            .navigationSubtitle(isNew ? "" : post.title)
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
                    .disabled(isSaving || post.title.isEmpty || post.slug.isEmpty)
                }
            }
            .frame(minWidth: 640, minHeight: 520)
        }
        .task { await loadData() }
    }

    private func loadData() async {
        allTags = (try? await supabase.schema(DB.blog).from("tags")
            .select("id, name, slug").order("name", ascending: true).execute().value) ?? []
        if !isNew {
            struct PT: Decodable { let tagId: String; enum CodingKeys: String, CodingKey { case tagId = "tag_id" } }
            let linked: [PT] = (try? await supabase.schema(DB.blog).from("post_tags")
                .select("tag_id").eq("post_id", value: post.id).execute().value) ?? []
            selectedTagIds = linked.map { $0.tagId }
        }
    }

    private func createTag() async {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let ins = BlogTagInsert(name: name, slug: slugify(name))
        if let tag: BlogTag = try? await supabase.schema(DB.blog).from("tags")
            .insert(ins).select().single().execute().value {
            allTags.append(tag); allTags.sort { $0.name < $1.name }
            selectedTagIds.append(tag.id)
        }
        newTagName = ""
    }

    private func save() async {
        isSaving = true
        do {
            let payload = BlogPostInsert(from: post, readTime: readTime)
            var postId = post.id
            if isNew {
                let saved: BlogPost = try await supabase.schema(DB.blog).from("posts")
                    .insert(payload).select().single().execute().value
                postId = saved.id; post = saved
            } else {
                try await supabase.schema(DB.blog).from("posts")
                    .update(payload).eq("id", value: postId).execute()
            }
            try await supabase.schema(DB.blog).from("post_tags")
                .delete().eq("post_id", value: postId).execute()
            if !selectedTagIds.isEmpty {
                let links = selectedTagIds.map { PostTagLink(postId: postId, tagId: $0) }
                try? await supabase.schema(DB.blog).from("post_tags").insert(links).execute()
            }
            onSave(post); dismiss()
        } catch {}
        isSaving = false
    }
}
