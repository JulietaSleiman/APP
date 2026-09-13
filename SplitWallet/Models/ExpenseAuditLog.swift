import Foundation

public enum ExpenseAuditAction: String, Codable, Sendable {
    case created
    case updated
    case deleted
}

public struct ExpenseAuditLog: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let expenseId: String
    public let groupId: String
    public let modifiedByUserId: String
    public let action: ExpenseAuditAction
    public let timestamp: Date
    public let previousAmount: Decimal?
    public let newAmount: Decimal?
    public let previousDescription: String?
    public let newDescription: String?

    public init(
        id: String = UUID().uuidString,
        expenseId: String,
        groupId: String,
        modifiedByUserId: String,
        action: ExpenseAuditAction,
        timestamp: Date = Date(),
        previousAmount: Decimal? = nil,
        newAmount: Decimal? = nil,
        previousDescription: String? = nil,
        newDescription: String? = nil
    ) {
        self.id = id
        self.expenseId = expenseId
        self.groupId = groupId
        self.modifiedByUserId = modifiedByUserId
        self.action = action
        self.timestamp = timestamp
        self.previousAmount = previousAmount
        self.newAmount = newAmount
        self.previousDescription = previousDescription
        self.newDescription = newDescription
    }
}
