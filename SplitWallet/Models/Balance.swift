import Foundation

public struct MemberNetBalance: Identifiable, Codable, Hashable, Sendable {
    public var id: String { "\(userId)_\(currency.rawValue)" }
    public let userId: String
    public let currency: Currency
    public let netAmount: Decimal

    public var isSettled: Bool {
        netAmount == 0
    }

    public var isCreditor: Bool {
        netAmount > 0
    }

    public var isDebtor: Bool {
        netAmount < 0
    }

    public init(userId: String, currency: Currency, netAmount: Decimal) {
        self.userId = userId
        self.currency = currency
        self.netAmount = netAmount
    }
}

public struct SimplifiedDebt: Identifiable, Codable, Hashable, Sendable {
    public var id: String { "\(fromUserId)->\(toUserId)_\(currency.rawValue)" }
    public let fromUserId: String
    public let toUserId: String
    public let amount: Decimal
    public let currency: Currency

    public init(fromUserId: String, toUserId: String, amount: Decimal, currency: Currency) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.amount = amount
        self.currency = currency
    }
}

public struct GroupCurrencyBalance: Identifiable, Codable, Hashable, Sendable {
    public var id: String { currency.rawValue }
    public let currency: Currency
    public let netBalances: [MemberNetBalance]
    public let simplifiedDebts: [SimplifiedDebt]

    public init(currency: Currency, netBalances: [MemberNetBalance], simplifiedDebts: [SimplifiedDebt]) {
        self.currency = currency
        self.netBalances = netBalances
        self.simplifiedDebts = simplifiedDebts
    }
}
