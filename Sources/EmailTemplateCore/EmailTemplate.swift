import Foundation

public struct EmailTemplate: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var subject: String
    public var bodyHtml: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        subject: String,
        bodyHtml: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.bodyHtml = bodyHtml
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func blank(now: Date = Date()) -> EmailTemplate {
        EmailTemplate(
            name: "Untitled Template",
            subject: "",
            bodyHtml: "",
            createdAt: now,
            updatedAt: now
        )
    }

    public func duplicated(now: Date = Date()) -> EmailTemplate {
        EmailTemplate(
            name: "\(name) Copy",
            subject: subject,
            bodyHtml: bodyHtml,
            createdAt: now,
            updatedAt: now
        )
    }
}

public struct TemplateDatabase: Codable, Equatable, Sendable {
    public var templates: [EmailTemplate]

    public init(templates: [EmailTemplate] = []) {
        self.templates = templates
    }
}
