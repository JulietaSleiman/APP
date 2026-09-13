import Foundation
import SwiftData

@Model
public final class SDUser {
    @Attribute(.unique) public var id: String
    public var name: String
    public var email: String
    public var avatarUrl: URL?
    public var authMethodRaw: String
    public var createdAt: Date

    public init(
        id: String,
        name: String,
        email: String,
        avatarUrl: URL? = nil,
        authMethodRaw: String = "apple",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.authMethodRaw = authMethodRaw
        self.createdAt = createdAt
    }

    public convenience init(from domain: User) {
        self.init(
            id: domain.id,
            name: domain.name,
            email: domain.email,
            avatarUrl: domain.avatarUrl,
            authMethodRaw: domain.authMethod.rawValue,
            createdAt: domain.createdAt
        )
    }

    public func toDomain() -> User {
        User(
            id: id,
            name: name,
            email: email,
            avatarUrl: avatarUrl,
            authMethod: AuthMethod(rawValue: authMethodRaw) ?? .apple,
            createdAt: createdAt
        )
    }
}

@Model
public final class SDGroup {
    @Attribute(.unique) public var id: String
    public var name: String
    public var defaultCurrencyRaw: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    public var members: [SDUser] = []

    @Relationship(deleteRule: .cascade)
    public var expenses: [SDExpense] = []

    @Relationship(deleteRule: .cascade)
    public var settlements: [SDSettlement] = []

    public init(
        id: String,
        name: String,
        defaultCurrencyRaw: String = "ARS",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.defaultCurrencyRaw = defaultCurrencyRaw
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public convenience init(from domain: Group) {
        self.init(
            id: domain.id,
            name: domain.name,
            defaultCurrencyRaw: domain.defaultCurrency.rawValue,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
        self.members = domain.members.map { SDUser(from: $0) }
    }

    public func toDomain() -> Group {
        Group(
            id: id,
            name: name,
            defaultCurrency: Currency(rawValue: defaultCurrencyRaw) ?? .ARS,
            members: members.map { $0.toDomain() },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
public final class SDSplitParticipant {
    public var userId: String
    public var shareValue: String
    public var computedAmount: String?

    public init(userId: String, shareValue: String, computedAmount: String? = nil) {
        self.userId = userId
        self.shareValue = shareValue
        self.computedAmount = computedAmount
    }

    public convenience init(from domain: SplitParticipant) {
        self.init(
            userId: domain.userId,
            shareValue: domain.shareValue.description,
            computedAmount: domain.computedAmount?.description
        )
    }

    public func toDomain() -> SplitParticipant {
        SplitParticipant(
            userId: userId,
            shareValue: Decimal(string: shareValue) ?? 1,
            computedAmount: computedAmount != nil ? Decimal(string: computedAmount!) : nil
        )
    }
}

@Model
public final class SDExpense {
    @Attribute(.unique) public var id: String
    public var groupId: String
    public var expenseDescription: String
    public var amount: String
    public var currencyRaw: String
    public var categoryRaw: String
    public var paidById: String
    public var date: Date
    public var splitTypeRaw: String
    public var receiptUrl: URL?
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    public var participants: [SDSplitParticipant] = []

    public init(
        id: String,
        groupId: String,
        expenseDescription: String,
        amount: String,
        currencyRaw: String,
        categoryRaw: String,
        paidById: String,
        date: Date = Date(),
        splitTypeRaw: String = "equal",
        receiptUrl: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.expenseDescription = expenseDescription
        self.amount = amount
        self.currencyRaw = currencyRaw
        self.categoryRaw = categoryRaw
        self.paidById = paidById
        self.date = date
        self.splitTypeRaw = splitTypeRaw
        self.receiptUrl = receiptUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public convenience init(from domain: Expense) {
        self.init(
            id: domain.id,
            groupId: domain.groupId,
            expenseDescription: domain.description,
            amount: domain.amount.description,
            currencyRaw: domain.currency.rawValue,
            categoryRaw: domain.category.rawValue,
            paidById: domain.paidById,
            date: domain.date,
            splitTypeRaw: domain.splitType.rawValue,
            receiptUrl: domain.receiptUrl,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
        self.participants = domain.participants.map { SDSplitParticipant(from: $0) }
    }

    public func toDomain() -> Expense {
        Expense(
            id: id,
            groupId: groupId,
            description: expenseDescription,
            amount: Decimal(string: amount) ?? 0,
            currency: Currency(rawValue: currencyRaw) ?? .ARS,
            category: ExpenseCategory(rawValue: categoryRaw) ?? .general,
            paidById: paidById,
            date: date,
            splitType: SplitType(rawValue: splitTypeRaw) ?? .equal,
            participants: participants.map { $0.toDomain() },
            receiptUrl: receiptUrl,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
public final class SDSettlement {
    @Attribute(.unique) public var id: String
    public var groupId: String
    public var fromUserId: String
    public var toUserId: String
    public var amount: String
    public var currencyRaw: String
    public var date: Date
    public var note: String?
    public var createdAt: Date

    public init(
        id: String,
        groupId: String,
        fromUserId: String,
        toUserId: String,
        amount: String,
        currencyRaw: String,
        date: Date = Date(),
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.amount = amount
        self.currencyRaw = currencyRaw
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }

    public convenience init(from domain: Settlement) {
        self.init(
            id: domain.id,
            groupId: domain.groupId,
            fromUserId: domain.fromUserId,
            toUserId: domain.toUserId,
            amount: domain.amount.description,
            currencyRaw: domain.currency.rawValue,
            date: domain.date,
            note: domain.note,
            createdAt: domain.createdAt
        )
    }

    public func toDomain() -> Settlement {
        Settlement(
            id: id,
            groupId: groupId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: Decimal(string: amount) ?? 0,
            currency: Currency(rawValue: currencyRaw) ?? .ARS,
            date: date,
            note: note,
            createdAt: createdAt
        )
    }
}
