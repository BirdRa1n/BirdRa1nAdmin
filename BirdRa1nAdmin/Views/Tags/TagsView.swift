// BirdRa1nAdmin/Views/Tags/TagsView.swift
import SwiftUI
import Supabase

struct TagsView: View {
    @Binding var toast: ToastMessage?
    @State private var tags: [BlogTag] = []
    @State private var isLoading = true
    @State private var newName = ""
    @State private var isSaving = false
    @State private var deleteTarget: BlogTag?
    @State private var showDelete = false
    @State private var searchText = ""
    @FocusState private var fieldFocused: Bool

    private var filtered: [BlogTag] {
        guard !searchText.isEmpty else { return tags }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        HSplitView {
            // Painel de criação (sidebar esquerda)
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nova Tag")
                            .font(.headline)
                        Text("Tags organizam posts por tema. O slug é gerado automaticamente.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nome").font(.footnote).fontWeight(.medium).foregroundStyle(.secondary)
                        TextField("ex: SwiftUI, Tutorial...", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .focused($fieldFocused)
                            .onSubmit { Task { await createTag() } }

                        if !newName.isEmpty {
                            Text("Slug: /\(slugify(newName))")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }

                    Button {
                        Task { await createTag() }
                    } label: {
                        if isSaving {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Criando...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Criar Tag", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving || newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)

                    Divider()

                    // Estatísticas
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(tags.count) tag\(tags.count == 1 ? "" : "s") no total",
                              systemImage: "tag")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(16)

                Spacer()
            }
            .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)
            .background(Color(nsColor: .controlBackgroundColor))

            // Lista de tags
            VStack(spacing: 0) {
                if isLoading {
                    List { ForEach(0..<8) { _ in SkeletonRow() } }.listStyle(.inset)
                } else if filtered.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView {
                            Label("Nenhuma tag criada", systemImage: "tag")
                        } description: {
                            Text("Crie sua primeira tag usando o painel ao lado")
                        } actions: {
                            Button("Criar tag") { fieldFocused = true }
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    List {
                        ForEach(filtered) { tag in
                            TagListRow(tag: tag) {
                                deleteTarget = tag; showDelete = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTarget = tag; showDelete = true
                                } label: {
                                    Label("Deletar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .alternatingRowBackgrounds()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .searchable(text: $searchText, prompt: "Buscar tags...")
        }
        .navigationTitle("Tags")
        .confirmationDialog("Deletar Tag?", isPresented: $showDelete, presenting: deleteTarget) { t in
            Button("Deletar \"\(t.name)\"", role: .destructive) { deleteTag(t) }
        } message: { t in
            Text("A tag \"\(t.name)\" será removida de todos os posts. Esta ação não pode ser desfeita.")
        }
        .task { await loadTags() }
    }

    private func loadTags() async {
        isLoading = true
        tags = (try? await supabase.schema(DB.blog).from("tags")
            .select("id, name, slug")
            .order("name", ascending: true)
            .execute().value) ?? []
        isLoading = false
    }

    private func createTag() async {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isSaving = true

        let ins = BlogTagInsert(name: name, slug: slugify(name))
        do {
            let tag: BlogTag = try await supabase.schema(DB.blog).from("tags")
                .insert(ins).select().single().execute().value
            tags.append(tag)
            tags.sort { $0.name < $1.name }
            toast = .init(type: .success, message: "Tag \"\(tag.name)\" criada!")
            newName = ""
        } catch {
            toast = .init(type: .error, message: "Erro: slug duplicado ou nome inválido")
        }
        isSaving = false
    }

    private func deleteTag(_ tag: BlogTag) {
        Task {
            try? await supabase.schema(DB.blog).from("post_tags")
                .delete().eq("tag_id", value: tag.id).execute()
            try? await supabase.schema(DB.blog).from("tags")
                .delete().eq("id", value: tag.id).execute()
            tags.removeAll { $0.id == tag.id }
            toast = .init(type: .success, message: "Tag \"\(tag.name)\" removida")
        }
    }
}

// MARK: - Tag List Row
struct TagListRow: View {
    let tag: BlogTag
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .foregroundStyle(.tint)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 3) {
                Text(tag.name)
                    .font(.subheadline).fontWeight(.medium)
                Text("/\(tag.slug)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash").font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 3)
    }
}
