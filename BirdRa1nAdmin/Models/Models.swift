// BirdRa1nAdmin/Models/Models.swift
import Foundation

// MARK: - Admin
struct AdminUser: Decodable, Identifiable {
    let id: String
    let userId: String
    let name: String?
    let email: String
    let role: String

    var displayName: String { name ?? email }
    var firstWord: String { displayName.components(separatedBy: " ").first ?? displayName }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, email, role
    }
}

// MARK: - Project
struct Project: Codable, Identifiable {
    let id: String
    var categoryId: String?
    var title: String
    var slug: String
    var description: String?
    var content: String?
    var thumbnailUrl: String?
    var demoUrl: String?
    var repoUrl: String?
    var techStack: [String]
    var featured: Bool
    var status: String
    var viewsCount: Int
    let createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId   = "category_id"
        case title, slug, description, content
        case thumbnailUrl = "thumbnail_url"
        case demoUrl      = "demo_url"
        case repoUrl      = "repo_url"
        case techStack    = "tech_stack"
        case featured, status
        case viewsCount   = "views_count"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }

    static func empty() -> Project {
        Project(id: UUID().uuidString, categoryId: nil, title: "", slug: "",
                description: nil, content: nil, thumbnailUrl: nil,
                demoUrl: nil, repoUrl: nil, techStack: [], featured: false,
                status: "draft", viewsCount: 0, createdAt: nil, updatedAt: nil)
    }
}

struct ProjectInsert: Encodable {
    var categoryId: String?
    var title: String
    var slug: String
    var description: String?
    var content: String?
    var thumbnailUrl: String?
    var demoUrl: String?
    var repoUrl: String?
    var techStack: [String]
    var featured: Bool
    var status: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case categoryId   = "category_id"
        case title, slug, description, content
        case thumbnailUrl = "thumbnail_url"
        case demoUrl      = "demo_url"
        case repoUrl      = "repo_url"
        case techStack    = "tech_stack"
        case featured, status
        case updatedAt    = "updated_at"
    }

    init(from p: Project) {
        categoryId   = p.categoryId.flatMap { $0.isEmpty ? nil : $0 }
        title        = p.title
        slug         = p.slug
        description  = p.description.flatMap { $0.isEmpty ? nil : $0 }
        content      = p.content.flatMap { $0.isEmpty ? nil : $0 }
        thumbnailUrl = p.thumbnailUrl.flatMap { $0.isEmpty ? nil : $0 }
        demoUrl      = p.demoUrl.flatMap { $0.isEmpty ? nil : $0 }
        repoUrl      = p.repoUrl.flatMap { $0.isEmpty ? nil : $0 }
        techStack    = p.techStack
        featured     = p.featured
        status       = p.status
        updatedAt    = ISO8601DateFormatter().string(from: Date())
    }
}

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String?
}

// MARK: - Blog Post
struct BlogPost: Codable, Identifiable {
    let id: String
    var authorId: String?
    var title: String
    var slug: String
    var excerpt: String?
    var content: String?
    var coverUrl: String?
    var status: String
    var featured: Bool
    var viewsCount: Int
    var readTimeMin: Int?
    var publishedAt: String?
    let createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId    = "author_id"
        case title, slug, excerpt, content
        case coverUrl    = "cover_url"
        case status, featured
        case viewsCount  = "views_count"
        case readTimeMin = "read_time_min"
        case publishedAt = "published_at"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    static func empty() -> BlogPost {
        BlogPost(id: UUID().uuidString, authorId: nil, title: "", slug: "",
                 excerpt: nil, content: nil, coverUrl: nil, status: "draft",
                 featured: false, viewsCount: 0, readTimeMin: 1,
                 publishedAt: nil, createdAt: nil, updatedAt: nil)
    }
}

struct BlogPostInsert: Encodable {
    var title: String
    var slug: String
    var excerpt: String?
    var content: String?
    var coverUrl: String?
    var status: String
    var featured: Bool
    var readTimeMin: Int?
    var publishedAt: String?
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case title, slug, excerpt, content
        case coverUrl    = "cover_url"
        case status, featured
        case readTimeMin = "read_time_min"
        case publishedAt = "published_at"
        case updatedAt   = "updated_at"
    }

    init(from post: BlogPost, readTime: Int) {
        title       = post.title
        slug        = post.slug
        excerpt     = post.excerpt.flatMap { $0.isEmpty ? nil : $0 }
        content     = post.content.flatMap { $0.isEmpty ? nil : $0 }
        coverUrl    = post.coverUrl.flatMap { $0.isEmpty ? nil : $0 }
        status      = post.status
        featured    = post.featured
        readTimeMin = readTime
        publishedAt = post.status == "published"
            ? (post.publishedAt ?? ISO8601DateFormatter().string(from: Date()))
            : nil
        updatedAt   = ISO8601DateFormatter().string(from: Date())
    }
}

struct BlogTag: Codable, Identifiable {
    let id: String
    var name: String
    var slug: String
}

struct BlogTagInsert: Encodable {
    let name: String
    let slug: String
}

struct PostTagLink: Encodable {
    let postId: String
    let tagId: String
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case tagId  = "tag_id"
    }
}

// MARK: - Certificate
struct Certificate: Codable, Identifiable {
    let id: String
    var organizationId: String?
    var title: String
    var emission: String?
    var url: String?
    var skills: [String]
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case title, emission, url, skills
        case createdAt = "created_at"
    }

    static func empty() -> Certificate {
        Certificate(id: UUID().uuidString, organizationId: nil,
                    title: "", emission: nil, url: nil, skills: [], createdAt: nil)
    }
}

struct CertificateInsert: Encodable {
    var organizationId: String?
    var title: String
    var emission: String?
    var url: String?
    var skills: [String]

    enum CodingKeys: String, CodingKey {
        case organizationId = "organization_id"
        case title, emission, url, skills
    }

    init(from c: Certificate) {
        organizationId = c.organizationId.flatMap { $0.isEmpty ? nil : $0 }
        title          = c.title
        emission       = c.emission.flatMap { $0.isEmpty ? nil : $0 }
        url            = c.url.flatMap { $0.isEmpty ? nil : $0 }
        skills         = c.skills
    }
}

struct Organization: Codable, Identifiable {
    let id: String
    let name: String
    let logo: String?
    let email: String?
    let phone: String?
    let site: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, logo, email, phone, site
        case createdAt = "created_at"
    }
}

// MARK: - Store App
struct StoreApp: Codable, Identifiable {
    let id: String
    var name: String
    var bundleId: String
    var developer: String
    var subtitle: String?
    var appDescription: String?
    var iconUrl: String?
    var screenshots: [String]
    var category: String
    var minIosVersion: String
    var isBeta: Bool
    var featured: Bool
    var status: String
    let createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case bundleId       = "bundle_id"
        case developer, subtitle
        case appDescription = "description"
        case iconUrl        = "icon_url"
        case screenshots, category
        case minIosVersion  = "min_ios_version"
        case isBeta         = "is_beta"
        case featured, status
        case createdAt      = "created_at"
        case updatedAt      = "updated_at"
    }

    static func empty() -> StoreApp {
        StoreApp(id: UUID().uuidString, name: "", bundleId: "",
                 developer: "BirdRa1n", subtitle: nil, appDescription: nil,
                 iconUrl: nil, screenshots: [], category: "utilities",
                 minIosVersion: "15.0", isBeta: false, featured: false,
                 status: "draft", createdAt: nil, updatedAt: nil)
    }
}

struct StoreAppInsert: Encodable {
    var name: String
    var bundleId: String
    var developer: String
    var subtitle: String?
    var description: String?
    var iconUrl: String?
    var screenshots: [String]
    var category: String
    var minIosVersion: String
    var isBeta: Bool
    var featured: Bool
    var status: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case name
        case bundleId      = "bundle_id"
        case developer, subtitle, description
        case iconUrl       = "icon_url"
        case screenshots, category
        case minIosVersion = "min_ios_version"
        case isBeta        = "is_beta"
        case featured, status
        case updatedAt     = "updated_at"
    }

    init(from a: StoreApp) {
        name          = a.name
        bundleId      = a.bundleId
        developer     = a.developer
        subtitle      = a.subtitle.flatMap { $0.isEmpty ? nil : $0 }
        description   = a.appDescription.flatMap { $0.isEmpty ? nil : $0 }
        iconUrl       = a.iconUrl.flatMap { $0.isEmpty ? nil : $0 }
        screenshots   = a.screenshots
        category      = a.category
        minIosVersion = a.minIosVersion
        isBeta        = a.isBeta
        featured      = a.featured
        status        = a.status
        updatedAt     = ISO8601DateFormatter().string(from: Date())
    }
}

struct AppVersion: Codable, Identifiable {
    let id: String
    var appId: String?
    var version: String
    var buildNumber: Int
    var downloadUrl: String
    var sha256: String?
    var sizeBytes: Int?
    var changelog: String?
    var minIosVersion: String?
    var publishedAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case appId         = "app_id"
        case version
        case buildNumber   = "build_number"
        case downloadUrl   = "download_url"
        case sha256
        case sizeBytes     = "size_bytes"
        case changelog
        case minIosVersion = "min_ios_version"
        case publishedAt   = "published_at"
        case createdAt     = "created_at"
    }
}

struct AppVersionInsert: Encodable {
    let appId: String
    let version: String
    let buildNumber: Int
    let downloadUrl: String
    let sha256: String?
    let sizeBytes: Int?
    let changelog: String?
    let minIosVersion: String?

    enum CodingKeys: String, CodingKey {
        case appId         = "app_id"
        case version
        case buildNumber   = "build_number"
        case downloadUrl   = "download_url"
        case sha256
        case sizeBytes     = "size_bytes"
        case changelog
        case minIosVersion = "min_ios_version"
    }
}

// MARK: - Contact
struct ContactMessage: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let subject: String?
    let message: String
    var status: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, subject, message, status
        case createdAt = "created_at"
    }
}

struct ContactStatusUpdate: Encodable {
    let status: String
}

// MARK: - Dashboard
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
