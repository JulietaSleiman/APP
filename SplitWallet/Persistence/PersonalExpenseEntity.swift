import Foundation
import SwiftData

@Model
public final class SDPersonalExpense {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var expenseDescription: String
    public var amount: String
    public var currencyRaw: String
    public var categoryRaw: String
    public var date: Date
    public var note: String?
    public var createdAt: Date

    public init(
        id: String,
        userId: String,
        expenseDescription: String,
        amount: String,
        currencyRaw: String,
        categoryRaw: String,
        date: Date = Date(),
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.expenseDescription = expenseDescription
        self.amount = amount
        self.currencyRaw = currencyRaw
        self.categoryRaw = categoryRaw
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }

    public convenience init(from domain: PersonalExpense) {
        self.init(
            id: domain.id,
            userId: domain.userId,
            expenseDescription: domain.description,
            amount: domain.amount.description,
            currencyRaw: domain.currency.rawValue,
            categoryRaw: domain.category.rawValue,
            date: domain.date,
            note: domain.note,
            createdAt: domain.createdAt
        )
    }

    public func toDomain() -> PersonalExpense {
        PersonalExpense(
            id: id,
            userId: userId,
            description: expenseDescription,
            amount: Decimal(string: amount) ?? 0,
            currency: Currency(rawValue: currencyRaw) ?? .ARS,
            category: PersonalExpenseCategory(rawValue: categoryRaw) ?? .other,
            date: date,
            note: note,
            createdAt: createdAt
        )
    }
}
