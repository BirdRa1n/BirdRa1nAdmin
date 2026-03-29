// Sources/BirdRa1nAdmin/Views/Tags/TagsView.swift
import SwiftUI
import Supabase

struct TagsView: View {
    @Binding var toast: ToastMessage?
    @State private var tags: [BlogTag] = []
    @State private var isLoading = true
    @State private var newName = ""
    @State private var isSaving = false
    @State private var deleteTarget: BlogTag? = nil
    @State private var showDelete = false

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Tags", subtitle: "// blog.tags")
            SectionDivider()

            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOVA TAG").monoLabel().foregroundColor(.textMuted)
                        TextField("nome-da-tag", text: $newName)
                            .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced)).foregroundColor(.textPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 9).background(Color.bgCardAlt)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 3)).frame(width: 280)
                            .onSubmit { Task { await createTag() } }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(" ").monoLabel()
                        Button { Task { await createTag() } } label: {
                            HStack(spacing: 6) {
                                if isSaving { NeonSpinner() } else { Image(systemName: "plus").font(.system(size: 11)) }
                                Text("CRIAR")
                            }
                        }
                        .buttonStyle(NeonButtonStyle(variant: .primary))
                        .disabled(isSaving || newName.isEmpty)
                    }
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ForEach(0..<6) { _ in
                            RoundedRectangle(cornerRadius: 3).fill(Color.bgCard).frame(width: 80, height: 34).shimmer()
                        }
                    }
                } else if tags.isEmpty {
                    EmptyStateView(icon: "tag", title: "// Nenhuma tag ainda", subtitle: "Crie tags para organizar seus posts")
                        .frame(height: 200)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(tags) { tag in
                            TagItem(tag: tag) { deleteTarget = tag; showDelete = true }
                        }
                    }
                }
            }
            .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.bgPrimary)
        .confirmationDialog("Deletar Tag", isPresented: $showDelete, presenting: deleteTarget) { target in
            Button("Deletar", role: .destructive) { deleteTag(target) }
            Button("Cancelar", role: .cancel) {}
        } message: { target in Text("A tag \"\(target.name)\" será removida de todos os posts.") }
        .task { await loadTags() }
    }

    private func loadTags() async {
        isLoading = true
        tags = (try? await supabase.schema("blog").from("tags")
            .select().order("name", ascending: true).execute().value) ?? []
        isLoading = false
    }

    private func createTag() async {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true
        struct TagInsert: Encodable { let name: String; let slug: String }
        if let tag: BlogTag = try? await supabase.schema("blog").from("tags")
            .insert(TagInsert(name: newName.trimmingCharacters(in: .whitespaces), slug: slugify(newName)))
            .select().single().execute().value {
            tags.append(tag)
            tags.sort { $0.name < $1.name }
            toast = .init(type: .success, message: "Tag \"\(tag.name)\" criada!")
        }
        newName = ""; isSaving = false
    }

    private func deleteTag(_ tag: BlogTag) {
        Task {
            try? await supabase.schema("blog").from("tags").delete().eq("id", value: tag.id).execute()
            tags.removeAll { $0.id == tag.id }
            toast = .init(type: .success, message: "Tag removida")
        }
    }
}

// MARK: - Tag Item
struct TagItem: View {
    let tag: BlogTag
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag").font(.system(size: 10)).foregroundColor(.neon.opacity(0.6))
            Text(tag.name).font(.system(size: 11, design: .monospaced)).foregroundColor(.textPrimary)
            Text("/\(tag.slug)").font(.system(size: 9, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
            if hovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(.danger.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8).background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(hovered ? Color.neon.opacity(0.4) : Color.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovered)
    }
}
