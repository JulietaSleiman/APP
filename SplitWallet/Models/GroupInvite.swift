import Foundation

public struct GroupInvite: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let groupId: String
    public let inviteCode: String
    public let inviteURL: URL
    public let createdAt: Date
    public let expiresAt: Date?

    public init(
        id: String = UUID().uuidString,
        groupId: String,
        inviteCode: String,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.inviteCode = inviteCode
        self.inviteURL = URL(string: "https://splitwallet.app/join/\(inviteCode)")!
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }

    /// Genera un código legible de 6 caracteres alfanuméricos en mayúsculas (ej: "BARI24")
    public static func generateRandomCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}
