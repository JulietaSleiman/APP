import Foundation

public enum AuthMethod: String, Codable, Sendable {
    case apple
    case emailPassword = "email_password"
}

public struct User: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var email: String
    public var avatarUrl: URL?
    public var authMethod: AuthMethod
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        avatarUrl: URL? = nil,
        authMethod: AuthMethod = .apple,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.authMethod = authMethod
        self.createdAt = createdAt
    }
}
