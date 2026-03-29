// Sources/BirdRa1nAdmin/Services/AuthStore.swift
import SwiftUI
import Combine
import Supabase

@MainActor
final class AuthStore: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var currentUser: AdminUser?
    @Published var errorMessage: String?

    init() {
        Task { await checkSession() }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            try await fetchAdminRecord(userId: session.user.id.uuidString)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    private func checkSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            try await fetchAdminRecord(userId: session.user.id.uuidString)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    private func fetchAdminRecord(userId: String) async throws {
        let admins: [AdminUser] = try await supabase
            .from("administrators")
            .select("id,user_id,name,email,role")
            .eq("user_id", value: userId)
            .execute()
            .value
        guard let admin = admins.first else {
            try? await supabase.auth.signOut()
            throw SupabaseError.apiError("Acesso não autorizado. Você não é um administrador.")
        }
        currentUser = admin
    }
}

// MARK: - Model
struct AdminUser: Decodable, Identifiable {
    let id: String
    let userId: String?
    let name: String?
    let email: String?
    let role: String?

    var displayName: String { name ?? email ?? "Admin" }
    var firstWord: String { displayName.components(separatedBy: " ").first ?? displayName }
}
