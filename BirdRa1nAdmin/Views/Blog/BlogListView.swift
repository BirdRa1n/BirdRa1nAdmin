// Sources/BirdRa1nAdmin/Views/Blog/BlogListView.swift
import SwiftUI
import Supabase

struct BlogListView: View {
    @Binding var toast: ToastMessage?
    @State private var posts: [BlogPost] = []
    @State private var isLoading = true
    @State private var editingPost: BlogPost? = nil
    @State private var isCreatingNew = false
    @State private var deleteTarget: BlogPost? = nil
    @State private var showDelete = false

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Blog", subtitle: "// blog.posts") { isCreatingNew = true }
            SectionDivider()

            if isLoading {
                LoadingTable()
            } else if posts.isEmpty {
                EmptyStateView(icon: "doc.text", title: "// Nenhum post encontrado",
                               subtitle: "Clique em NOVO para criar seu primeiro post")
            } else {
                TableHeader(columns: [("Título", 0), ("Status", 0), ("Views", 0), ("Data", 0), ("Ações", 0)])
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(posts) { post in
                            BlogPostRow(post: post) { editingPost = post } onDelete: {
                                deleteTarget = post; showDelete = true
                            }
                        }
                    }
                }
            }
        }
        .background(Color.bgPrimary)
        .sheet(isPresented: $isCreatingNew) {
            BlogEditorView(post: BlogPost.empty(), isNew: true) { saved in
                posts.insert(saved, at: 0)
                toast = .init(type: .success, message: "Post criado!")
            }
        }
        .sheet(item: $editingPost) { post in
            BlogEditorView(post: post, isNew: false) { saved in
                if let idx = posts.firstIndex(where: { $0.id == saved.id }) { posts[idx] = saved }
                toast = .init(type: .success, message: "Post salvo!")
            }
        }
        .confirmationDialog("Deletar Post", isPresented: $showDelete, presenting: deleteTarget) { target in
            Button("Deletar", role: .destructive) { deletePost(target) }
            Button("Cancelar", role: .cancel) {}
        } message: { target in Text("Deletar \"\(target.title)\"? Esta ação não pode ser desfeita.") }
        .task { await loadPosts() }
    }

    private func loadPosts() async {
        isLoading = true
        posts = (try? await supabase.schema("blog").from("posts")
            .select("id,title,slug,status,featured,views_count,cover_url,created_at,published_at")
            .order("created_at", ascending: false).execute().value) ?? []
        isLoading = false
    }

    private func deletePost(_ post: BlogPost) {
        Task {
            do {
                try await supabase.schema("blog").from("posts").delete().eq("id", value: post.id).execute()
                posts.removeAll { $0.id == post.id }
                toast = .init(type: .success, message: "Post deletado")
            } catch {
                toast = .init(type: .error, message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Post Row
struct BlogPostRow: View {
    let post: BlogPost
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                if let coverUrl = post.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { img in img.resizable().aspectRatio(contentMode: .fill) }
                    placeholder: { Color.bgCardAlt }
                    .frame(width: 36, height: 36).clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                } else {
                    Color.bgCardAlt
                        .overlay(Text("MD").font(.system(size: 8, design: .monospaced)).foregroundColor(.neon))
                        .frame(width: 36, height: 36).clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.title).font(.system(size: 12, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(1)
                        if post.featured == true { TagChip(text: "DESTAQUE") }
                    }
                    Text("/\(post.slug)").font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let status = post.status { StatusBadge(status: status) }
            Spacer(minLength: 12)
            Text("\(post.viewsCount ?? 0)").font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted).frame(width: 60, alignment: .leading)
            Text(formatDate(post.createdAt)).font(.system(size: 11, design: .monospaced)).foregroundColor(.textMuted).frame(width: 100, alignment: .leading)
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
        VStack(spacing: 0) {
            EditorHeader(
                title: isNew ? "Novo Post" : "Editar Post",
                subtitle: isNew ? "// blog.posts.insert" : "// blog.posts.update",
                onBack: { dismiss() },
                onSave: { Task { await save() } },
                isSaving: isSaving,
                extra: AnyView(
                    Text("~\(readTime) min leitura")
                        .font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted)
                )
            )
            SectionDivider()

            ScrollView {
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 16) {
                        AdminCard {
                            VStack(spacing: 16) {
                                TerminalField(label: "Título", text: $post.title, placeholder: "Título do post...", required: true)
                                    .onChange(of: post.title) { _, new in if isNew { post.slug = slugify(new) } }
                                TerminalField(label: "Slug",
                                             text: Binding(get: { post.slug }, set: { post.slug = slugify($0) }),
                                             placeholder: "titulo-do-post", required: true, hint: "// URL: /blog/{slug}")
                                TerminalEditor(label: "Excerpt / Resumo",
                                               text: Binding(get: { post.excerpt ?? "" }, set: { post.excerpt = $0 }),
                                               placeholder: "Breve resumo para SEO...", minHeight: 70)
                            }
                        }
                        AdminCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("CONTEÚDO (MARKDOWN)").monoLabel().foregroundColor(.textMuted)
                                    Spacer()
                                    Text("\(wordCount) palavras").font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
                                }
                                TerminalEditor(label: "",
                                               text: Binding(get: { post.content ?? "" }, set: { post.content = $0 }),
                                               placeholder: "# Título\n\nEscreva o conteúdo aqui...", minHeight: 400)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        AdminCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PUBLICAÇÃO").monoLabel().foregroundColor(.textMuted)
                                StatusPicker(status: Binding(get: { post.status ?? "draft" }, set: { post.status = $0 }),
                                             options: ["draft", "published", "archived"])
                                ToggleRow(label: "Post em Destaque", description: "Exibir no topo do blog",
                                          isOn: Binding(get: { post.featured ?? false }, set: { post.featured = $0 }))
                            }
                        }
                        AdminCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("CAPA").monoLabel().foregroundColor(.textMuted)
                                TerminalField(label: "URL da Imagem",
                                             text: Binding(get: { post.coverUrl ?? "" }, set: { post.coverUrl = $0 }),
                                             placeholder: "https://...")
                                if let url = post.coverUrl, !url.isEmpty, let u = URL(string: url) {
                                    AsyncImage(url: u) { img in img.resizable().aspectRatio(contentMode: .fill) }
                                    placeholder: { Color.bgCardAlt }
                                    .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
                                }
                            }
                        }
                        AdminCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TAGS").monoLabel().foregroundColor(.textMuted)
                                HStack(spacing: 8) {
                                    TextField("Nova tag...", text: $newTagName)
                                        .textFieldStyle(.plain).font(.system(size: 11, design: .monospaced)).foregroundColor(.textPrimary)
                                        .padding(8).background(Color.bgCardAlt)
                                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .onSubmit { Task { await createTag() } }
                                    Button { Task { await createTag() } } label: { Image(systemName: "plus") }
                                        .buttonStyle(NeonButtonStyle(variant: .outline))
                                }
                                FlowLayout(spacing: 6) {
                                    ForEach(allTags) { tag in
                                        let selected = selectedTagIds.contains(tag.id)
                                        Button {
                                            if selected { selectedTagIds.removeAll { $0 == tag.id } }
                                            else { selectedTagIds.append(tag.id) }
                                        } label: { TagChip(text: tag.name, color: selected ? .neon : .textMuted) }
                                        .buttonStyle(.plain)
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
        .frame(minWidth: 820, minHeight: 620)
        .task { await loadData() }
    }

    private func loadData() async {
        allTags = (try? await supabase.schema("blog").from("tags")
            .select().order("name", ascending: true).execute().value) ?? []
    }

    private func createTag() async {
        guard !newTagName.isEmpty else { return }
        struct TagInsert: Encodable { let name: String; let slug: String }
        if let tag: BlogTag = try? await supabase.schema("blog").from("tags")
            .insert(TagInsert(name: newTagName, slug: slugify(newTagName)))
            .select().single().execute().value {
            allTags.append(tag)
            selectedTagIds.append(tag.id)
        }
        newTagName = ""
    }

    private func save() async {
        isSaving = true
        do {
            struct PostPayload: Encodable {
                var title: String; var slug: String; var excerpt: String?
                var content: String?; var coverUrl: String?; var status: String?
                var featured: Bool?; var readTimeMin: Int?; var publishedAt: String?; var updatedAt: String
            }
            let payload = PostPayload(
                title: post.title, slug: post.slug, excerpt: post.excerpt,
                content: post.content, coverUrl: post.coverUrl, status: post.status,
                featured: post.featured, readTimeMin: readTime,
                publishedAt: post.status == "published" ? ISO8601DateFormatter().string(from: Date()) : nil,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            var postId = post.id
            if isNew {
                let saved: BlogPost = try await supabase.schema("blog").from("posts")
                    .insert(payload).select().single().execute().value
                postId = saved.id; post = saved
            } else {
                try await supabase.schema("blog").from("posts").update(payload).eq("id", value: postId).execute()
            }
            try await supabase.schema("blog").from("post_tags").delete().eq("post_id", value: postId).execute()
            if !selectedTagIds.isEmpty {
                struct TagLink: Encodable { let postId: String; let tagId: String }
                for tagId in selectedTagIds {
                    try? await supabase.schema("blog").from("post_tags")
                        .insert(TagLink(postId: postId, tagId: tagId)).execute()
                }
            }
            onSave(post); dismiss()
        } catch {}
        isSaving = false
    }
}
