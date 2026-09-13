import Foundation

public enum PersonalExpenseCategory: String, Codable, CaseIterable, Sendable {
    case food
    case transport
    case housing
    case utilities
    case shopping
    case entertainment
    case health
    case subscriptions
    case education
    case other

    public var displayName: String {
        switch self {
        case .food: return "Alimentación"
        case .transport: return "Transporte"
        case .housing: return "Vivienda"
        case .utilities: return "Servicios"
        case .shopping: return "Compras"
        case .entertainment: return "Ocio y Salidas"
        case .health: return "Salud"
        case .subscriptions: return "Suscripciones"
        case .education: return "Educación"
        case .other: return "Otros"
        }
    }

    public var systemIcon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "popcorn.fill"
        case .health: return "heart.fill"
        case .subscriptions: return "play.rectangle.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

public struct PersonalExpense: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let userId: String
    public var description: String
    public var amount: Decimal
    public var currency: Currency
    public var category: PersonalExpenseCategory
    public var date: Date
    public var note: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        description: String,
        amount: Decimal,
        currency: Currency = .ARS,
        category: PersonalExpenseCategory = .other,
        date: Date = Date(),
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.description = description
        self.amount = amount
        self.currency = currency
        self.category = category
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }
}
