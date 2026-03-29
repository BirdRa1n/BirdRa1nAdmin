// Sources/BirdRa1nAdmin/Models/Models.swift
import Foundation
import Combine

// MARK: - Project
struct Project: Codable, Identifiable {
    let id: String
    var title: String
    var slug: String
    var description: String?
    var content: String?
    var thumbnailUrl: String?
    var demoUrl: String?
    var repoUrl: String?
    var techStack: [String]?
    var categoryId: String?
    var featured: Bool?
    var status: String?
    var viewsCount: Int?
    var createdAt: String?
    var updatedAt: String?

    static func empty() -> Project {
        Project(id: UUID().uuidString, title: "", slug: "", description: nil,
                content: nil, thumbnailUrl: nil, demoUrl: nil, repoUrl: nil,
                techStack: [], categoryId: nil, featured: false,
                status: "draft", viewsCount: 0, createdAt: nil, updatedAt: nil)
    }
}

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String?
}

// MARK: - Blog
struct BlogPost: Codable, Identifiable {
    let id: String
    var title: String
    var slug: String
    var excerpt: String?
    var content: String?
    var coverUrl: String?
    var status: String?
    var featured: Bool?
    var readTimeMin: Int?
    var viewsCount: Int?
    var publishedAt: String?
    var createdAt: String?
    var updatedAt: String?

    static func empty() -> BlogPost {
        BlogPost(id: UUID().uuidString, title: "", slug: "", excerpt: nil,
                 content: nil, coverUrl: nil, status: "draft",
                 featured: false, readTimeMin: 1, viewsCount: 0,
                 publishedAt: nil, createdAt: nil, updatedAt: nil)
    }
}

struct BlogTag: Codable, Identifiable {
    let id: String
    var name: String
    var slug: String
}

// MARK: - Certificate
struct Certificate: Codable, Identifiable {
    let id: String
    var title: String
    var organizationId: String?
    var emission: String?
    var url: String?
    var skills: [String]?
    var organization: Organization?

    static func empty() -> Certificate {
        Certificate(id: UUID().uuidString, title: "", organizationId: nil,
                    emission: nil, url: nil, skills: [], organization: nil)
    }
}

struct Organization: Codable, Identifiable {
    let id: String
    let name: String
    let logo: String?
}

// MARK: - Apps (AltStore)
struct StoreApp: Codable, Identifiable {
    let id: String
    var name: String
    var bundleId: String
    var developer: String?
    var subtitle: String?
    var description: String?
    var iconUrl: String?
    var category: String?
    var minIosVersion: String?
    var isBeta: Bool?
    var featured: Bool?
    var status: String?
    var createdAt: String?
    var updatedAt: String?

    static func empty() -> StoreApp {
        StoreApp(id: UUID().uuidString, name: "", bundleId: "",
                 developer: "BirdRa1n", subtitle: nil, description: nil,
                 iconUrl: nil, category: "utilities", minIosVersion: "15.0",
                 isBeta: false, featured: false, status: "draft",
                 createdAt: nil, updatedAt: nil)
    }
}

struct AppVersion: Codable, Identifiable {
    let id: String
    var appId: String?
    var version: String
    var buildNumber: Int?
    var downloadUrl: String
    var sha256: String?
    var sizeBytes: Int?
    var changelog: String?
    var minIosVersion: String?
    var publishedAt: String?
}

// MARK: - Contact
struct ContactMessage: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let subject: String?
    let message: String
    var status: String?
    let createdAt: String?
}

// MARK: - Dashboard Stats
struct DashboardStats {
    var projects: Int = 0
    var posts: Int = 0
    var newMessages: Int = 0
    var certificates: Int = 0
    var apps: Int = 0
    var totalViews: Int = 0
    var recentPosts: [BlogPost] = []
    var recentMessages: [ContactMessage] = []
}
