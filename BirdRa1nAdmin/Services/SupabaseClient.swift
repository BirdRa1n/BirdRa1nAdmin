// Sources/BirdRa1nAdmin/Services/SupabaseClient.swift
import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "")!,
  supabaseKey: ""
)

// MARK: - Errors
enum SupabaseError: LocalizedError {
    case notFound
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:          return "Registro não encontrado"
        case .apiError(let m):   return m
        }
    }
}
