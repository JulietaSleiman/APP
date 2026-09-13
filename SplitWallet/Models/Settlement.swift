import Foundation

public struct Settlement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let groupId: String
    public let fromUserId: String
    public let toUserId: String
    public var amount: Decimal
    public var currency: Currency
    public var date: Date
    public var note: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        groupId: String,
        fromUserId: String,
        toUserId: String,
        amount: Decimal,
        currency: Currency,
        date: Date = Date(),
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.amount = amount
        self.currency = currency
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }
}
