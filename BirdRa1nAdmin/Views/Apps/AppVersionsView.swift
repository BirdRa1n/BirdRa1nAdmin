// BirdRa1nAdmin/Views/Apps/AppVersionsView.swift
import SwiftUI
import Supabase

// MARK: - Versões embutidas no Form do editor de app
struct AppVersionsInlineView: View {
    let appId: String

    @State private var versions: [AppVersion] = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var deleteTarget: AppVersion?
    @State private var showDelete = false

    var body: some View {
        Group {
            if isLoading {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Carregando versões...").font(.subheadline).foregroundStyle(.secondary)
                }
            } else if versions.isEmpty {
                Label("Nenhuma versão publicada ainda", systemImage: "tray")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(Array(versions.enumerated()), id: \.element.id) { idx, ver in
                    VersionListRow(version: ver, isLatest: idx == 0) {
                        deleteTarget = ver; showDelete = true
                    }
                }
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Adicionar Versão", systemImage: "plus.circle")
            }
        }
        .confirmationDialog("Remover Versão?", isPresented: $showDelete, presenting: deleteTarget) { t in
            Button("Remover v\(t.version)", role: .destructive) { deleteVersion(t) }
        } message: { _ in
            Text("Esta versão será removida permanentemente do source.")
        }
        .sheet(isPresented: $showAddSheet) {
            AddVersionSheet(appId: appId) { saved in
                versions.insert(saved, at: 0)
            }
        }
        .task { await loadVersions() }
    }

    private func loadVersions() async {
        isLoading = true
        versions = (try? await supabase.schema(DB.store).from("app_versions")
            .select("id, app_id, version, build_number, download_url, sha256, size_bytes, changelog, min_ios_version, published_at, created_at")
            .eq("app_id", value: appId)
            .order("published_at", ascending: false)
            .execute().value) ?? []
        isLoading = false
    }

    private func deleteVersion(_ ver: AppVersion) {
        Task {
            try? await supabase.schema(DB.store).from("app_versions")
                .delete().eq("id", value: ver.id).execute()
            versions.removeAll { $0.id == ver.id }
        }
    }
}

// MARK: - Version Row dentro do Form
struct VersionListRow: View {
    let version: AppVersion
    let isLatest: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("v\(version.version)")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Build \(version.buildNumber)")
                        .font(.caption).foregroundStyle(.secondary)
                    if isLatest {
                        TagChip(text: "Mais recente", color: .green)
                    }
                }
                HStack(spacing: 12) {
                    if let size = version.sizeBytes {
                        Label(String(format: "%.1f MB", Double(size) / 1_048_576),
                              systemImage: "arrow.down.circle")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    Label(formatDate(version.publishedAt), systemImage: "calendar")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash").font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sheet para adicionar versão
struct AddVersionSheet: View {
    @Environment(\.dismiss) var dismiss
    let appId: String
    let onSave: (AppVersion) -> Void

    @State private var version = ""
    @State private var build = "1"
    @State private var downloadUrl = ""
    @State private var sha256 = ""
    @State private var sizeBytes = ""
    @State private var changelog = ""
    @State private var minIos = ""
    @State private var isSaving = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Identificação") {
                    AppTextField(label: "Versão", text: $version,
                                 placeholder: "1.0.0", required: true,
                                 hint: "Número semântico, ex: 1.2.3")
                    AppTextField(label: "Build Number", text: $build,
                                 placeholder: "1", required: true)
                }

                Section("Distribuição") {
                    AppTextField(label: "URL de Download", text: $downloadUrl,
                                 placeholder: "https://...", required: true)
                    AppTextField(label: "SHA256 (opcional)", text: $sha256,
                                 placeholder: "Hash para verificação de integridade")
                    AppTextField(label: "Tamanho em bytes (opcional)", text: $sizeBytes,
                                 placeholder: "10485760")
                    AppTextField(label: "iOS mínimo (override)", text: $minIos,
                                 placeholder: "Deixe vazio para usar o padrão do app")
                }

                Section("Changelog") {
                    AppTextEditor(label: "O que há de novo",
                                  text: $changelog,
                                  placeholder: "Descreva as mudanças desta versão...",
                                  minHeight: 80)
                }

                if let err = errorMsg {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Nova Versão")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if isSaving { ProgressView().controlSize(.small) }
                        else { Text("Adicionar") }
                    }
                    .disabled(isSaving || version.isEmpty || downloadUrl.isEmpty)
                }
            }
            .frame(minWidth: 480, minHeight: 420)
        }
    }

    private func save() async {
        isSaving = true
        errorMsg = nil

        guard let buildInt = Int(build), buildInt > 0 else {
            errorMsg = "Build number deve ser um número inteiro positivo"
            isSaving = false
            return
        }

        let payload = AppVersionInsert(
            appId: appId,
            version: version,
            buildNumber: buildInt,
            downloadUrl: downloadUrl,
            sha256: sha256.isEmpty ? nil : sha256,
            sizeBytes: sizeBytes.isEmpty ? nil : Int(sizeBytes),
            changelog: changelog.isEmpty ? nil : changelog,
            minIosVersion: minIos.isEmpty ? nil : minIos
        )

        do {
            let saved: AppVersion = try await supabase.schema(DB.store).from("app_versions")
                .insert(payload).select().single().execute().value
            onSave(saved)
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
        isSaving = false
    }
}
