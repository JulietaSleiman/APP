import Foundation

public enum Currency: String, Codable, CaseIterable, Sendable {
    case ARS = "ARS"
    case USD = "USD"
    case EUR = "EUR"
    case BRL = "BRL"
    case CLP = "CLP"

    public var symbol: String {
        switch self {
        case .ARS: return "$"
        case .USD: return "US$"
        case .EUR: return "€"
        case .BRL: return "R$"
        case .CLP: return "CLP$"
        }
    }
}

public struct Group: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var defaultCurrency: Currency
    public var members: [User]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        defaultCurrency: Currency = .ARS,
        members: [User] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.defaultCurrency = defaultCurrency
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
