// BirdRa1nAdmin/Services/AuthStore.swift
import SwiftUI
import Combine
import Supabase

@MainActor
final class AuthStore: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true      // começa true — aguarda checkSession
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
        } catch let err as AppError {
            errorMessage = err.localizedDescription
            try? await supabase.auth.signOut()
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
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.session
            try await fetchAdminRecord(userId: session.user.id.uuidString)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    private func fetchAdminRecord(userId: String) async throws {
        let admins: [AdminUser] = try await supabase
            .schema(DB.admin)
            .from("administrators")
            .select("id, user_id, name, email, role")
            .eq("user_id", value: userId)
            .execute()
            .value

        guard let admin = admins.first else {
            throw AppError.unauthorized
        }
        currentUser = admin
    }
}
