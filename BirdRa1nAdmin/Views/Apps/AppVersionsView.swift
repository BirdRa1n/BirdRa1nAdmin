// Sources/BirdRa1nAdmin/Views/Apps/AppVersionsView.swift
import SwiftUI
import Supabase

struct AppVersionsView: View {
    let appId: String
    @Binding var toast: ToastMessage?

    @State private var versions: [AppVersion] = []
    @State private var isLoading = true
    @State private var showAdd = false
    @State private var deleteTarget: AppVersion? = nil
    @State private var showDelete = false

    @State private var vVersion = ""
    @State private var vBuild = "1"
    @State private var vDownloadUrl = ""
    @State private var vSha256 = ""
    @State private var vSizeBytes = ""
    @State private var vChangelog = ""
    @State private var vMinIos = ""
    @State private var isSavingVersion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("VERSÕES").monoLabel().foregroundColor(.textMuted)
                Spacer()
                Button { showAdd.toggle() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 10))
                        Text("NOVA VERSÃO")
                    }
                }
                .buttonStyle(NeonButtonStyle(variant: .outline))
            }
            .padding(.bottom, 12)

            if showAdd {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TerminalField(label: "Versão", text: $vVersion, placeholder: "1.0.0")
                        TerminalField(label: "Build", text: $vBuild, placeholder: "1")
                    }
                    TerminalField(label: "Download URL", text: $vDownloadUrl, placeholder: "https://...", required: true)
                    HStack(spacing: 10) {
                        TerminalField(label: "SHA256", text: $vSha256, placeholder: "hash opcional...")
                        TerminalField(label: "Tamanho (bytes)", text: $vSizeBytes, placeholder: "1024000")
                    }
                    TerminalField(label: "iOS Mínimo (override)", text: $vMinIos,
                                 placeholder: "deixe vazio para usar o padrão do app")
                    TerminalEditor(label: "Changelog", text: $vChangelog,
                                   placeholder: "O que mudou nesta versão...", minHeight: 70)
                    HStack {
                        Spacer()
                        Button("Cancelar") { showAdd = false }.buttonStyle(NeonButtonStyle(variant: .outline))
                        Button {
                            Task { await addVersion() }
                        } label: {
                            HStack(spacing: 6) {
                                if isSavingVersion { NeonSpinner() } else { Image(systemName: "plus").font(.system(size: 11)) }
                                Text("ADICIONAR")
                            }
                        }
                        .buttonStyle(NeonButtonStyle(variant: .primary))
                        .disabled(isSavingVersion || vVersion.isEmpty || vDownloadUrl.isEmpty)
                    }
                }
                .padding(14).background(Color.bgCardAlt)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.neon.opacity(0.3), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.bottom, 12)
            }

            if isLoading {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 3).fill(Color.bgCardAlt)
                        .frame(height: 52).shimmer().padding(.bottom, 4)
                }
            } else if versions.isEmpty {
                Text("// Nenhuma versão ainda")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.textMuted.opacity(0.4))
                    .padding(.vertical, 16).frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(Array(versions.enumerated()), id: \.element.id) { idx, ver in
                    VersionRow(version: ver, isLatest: idx == 0) {
                        deleteTarget = ver; showDelete = true
                    }
                }
            }
        }
        .confirmationDialog("Remover Versão", isPresented: $showDelete, presenting: deleteTarget) { target in
            Button("Remover", role: .destructive) { deleteVersion(target) }
            Button("Cancelar", role: .cancel) {}
        } message: { _ in Text("Esta versão será removida do AltStore source.") }
        .task { await loadVersions() }
    }

    private func loadVersions() async {
        isLoading = true
        versions = (try? await supabase.schema("store").from("app_versions")
            .select("id,app_id,version,build_number,download_url,sha256,size_bytes,changelog,min_ios_version,published_at")
            .eq("app_id", value: appId)
            .order("published_at", ascending: false)
            .execute().value) ?? []
        isLoading = false
    }

    private func addVersion() async {
        isSavingVersion = true
        struct VersionPayload: Encodable {
            let appId: String; let version: String; let buildNumber: Int?
            let downloadUrl: String; let sha256: String?; let sizeBytes: Int?
            let changelog: String?; let minIosVersion: String?; let publishedAt: String
        }
        let payload = VersionPayload(
            appId: appId, version: vVersion, buildNumber: Int(vBuild),
            downloadUrl: vDownloadUrl,
            sha256: vSha256.isEmpty ? nil : vSha256,
            sizeBytes: vSizeBytes.isEmpty ? nil : Int(vSizeBytes),
            changelog: vChangelog.isEmpty ? nil : vChangelog,
            minIosVersion: vMinIos.isEmpty ? nil : vMinIos,
            publishedAt: ISO8601DateFormatter().string(from: Date())
        )
        if let saved: AppVersion = try? await supabase.schema("store").from("app_versions")
            .insert(payload).select().single().execute().value {
            versions.insert(saved, at: 0)
            toast = .init(type: .success, message: "Versão \(saved.version) adicionada!")
            vVersion = ""; vBuild = "1"; vDownloadUrl = ""; vSha256 = ""; vSizeBytes = ""; vChangelog = ""; vMinIos = ""
            showAdd = false
        }
        isSavingVersion = false
    }

    private func deleteVersion(_ ver: AppVersion) {
        Task {
            try? await supabase.schema("store").from("app_versions").delete().eq("id", value: ver.id).execute()
            versions.removeAll { $0.id == ver.id }
            toast = .init(type: .success, message: "Versão removida")
        }
    }
}

// MARK: - Version Row
struct VersionRow: View {
    let version: AppVersion
    let isLatest: Bool
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("v\(version.version)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.neon)
                Text("build \(version.buildNumber ?? 0)")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
                if isLatest { TagChip(text: "LATEST") }
            }
            Spacer()
            if let size = version.sizeBytes {
                Text(String(format: "%.1f MB", Double(size) / 1_048_576))
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
            }
            Text(formatDate(version.publishedAt))
                .font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted.opacity(0.4))
            if hovered {
                Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 11)) }
                    .buttonStyle(.plain).foregroundColor(.danger.opacity(0.7))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.bgCardAlt)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .padding(.bottom, 4)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: hovered)
    }
}
