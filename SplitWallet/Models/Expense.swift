import Foundation

public enum ExpenseCategory: String, Codable, CaseIterable, Sendable {
    case general
    case groceries
    case restaurant
    case transport
    case accommodation
    case entertainment
    case utilities

    public var displayName: String {
        switch self {
        case .general: return "General"
        case .groceries: return "Supermercado"
        case .restaurant: return "Restaurante y Bares"
        case .transport: return "Transporte"
        case .accommodation: return "Alojamiento"
        case .entertainment: return "Entretenimiento"
        case .utilities: return "Servicios"
        }
    }

    public var systemIcon: String {
        switch self {
        case .general: return "cart.fill"
        case .groceries: return "basket.fill"
        case .restaurant: return "fork.knife"
        case .transport: return "car.fill"
        case .accommodation: return "bed.double.fill"
        case .entertainment: return "ticket.fill"
        case .utilities: return "bolt.fill"
        }
    }
}

public enum SplitType: String, Codable, CaseIterable, Sendable {
    case equal
    case exact
    case percentage
    case shares

    public var displayName: String {
        switch self {
        case .equal: return "Partes Iguales"
        case .exact: return "Montos Exactos"
        case .percentage: return "Porcentajes"
        case .shares: return "Por Partes"
        }
    }
}

public struct SplitParticipant: Identifiable, Codable, Hashable, Sendable {
    public var id: String { userId }
    public let userId: String
    public var shareValue: Decimal
    public var computedAmount: Decimal?

    public init(userId: String, shareValue: Decimal = 1, computedAmount: Decimal? = nil) {
        self.userId = userId
        self.shareValue = shareValue
        self.computedAmount = computedAmount
    }
}

public struct Expense: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let groupId: String
    public var description: String
    public var amount: Decimal
    public var currency: Currency
    public var category: ExpenseCategory
    public var paidById: String
    public var date: Date
    public var splitType: SplitType
    public var participants: [SplitParticipant]
    public var receiptUrl: URL?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        groupId: String,
        description: String,
        amount: Decimal,
        currency: Currency,
        category: ExpenseCategory = .general,
        paidById: String,
        date: Date = Date(),
        splitType: SplitType = .equal,
        participants: [SplitParticipant] = [],
        receiptUrl: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.description = description
        self.amount = amount
        self.currency = currency
        self.category = category
        self.paidById = paidById
        self.date = date
        self.splitType = splitType
        self.participants = participants
        self.receiptUrl = receiptUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
