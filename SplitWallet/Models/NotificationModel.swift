import Foundation

public enum AppNotificationType: String, Codable, Sendable {
    case expenseCreated = "expense_created"
    case settlementRecorded = "settlement_recorded"
    case debtReminder = "debt_reminder"
}

public struct AppNotificationPayload: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let type: AppNotificationType
    public let groupId: String
    public let groupName: String
    public let title: String
    public let body: String
    public let targetUserId: String
    public let amount: Decimal?
    public let currency: Currency?
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        type: AppNotificationType,
        groupId: String,
        groupName: String,
        title: String,
        body: String,
        targetUserId: String,
        amount: Decimal? = nil,
        currency: Currency? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.groupId = groupId
        self.groupName = groupName
        self.title = title
        self.body = body
        self.targetUserId = targetUserId
        self.amount = amount
        self.currency = currency
        self.timestamp = timestamp
    }
}
