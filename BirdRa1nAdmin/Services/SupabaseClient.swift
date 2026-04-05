// BirdRa1nAdmin/Services/SupabaseClient.swift
import Foundation
import Supabase

// MARK: - Credenciais
// Preencha com os valores do seu projeto:
// Supabase Dashboard → Settings → API
private let supabaseURL = ""
private let supabaseKey = ""

let supabase = SupabaseClient(
    supabaseURL: URL(string: supabaseURL)!,
    supabaseKey: supabaseKey
)

// MARK: - Schemas
enum DB {
    static let admin     = "admin"
    static let portfolio = "portfolio"
    static let blog      = "blog"
    static let store     = "store"
}

// MARK: - Erros
enum AppError: LocalizedError {
    case notFound
    case unauthorized
    case api(String)

    var errorDescription: String? {
        switch self {
        case .notFound:      return "Registro não encontrado"
        case .unauthorized:  return "Acesso não autorizado. Você não é um administrador."
        case .api(let m):    return m
        }
    }
}
