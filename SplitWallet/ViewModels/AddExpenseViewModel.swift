import Foundation
import Observation

@Observable
public final class AddExpenseViewModel {
    public var description: String = ""
    public var amountString: String = ""
    public var currency: Currency
    public var category: ExpenseCategory = .general
    public var paidById: String
    public var splitType: SplitType = .equal
    public var participants: [SplitParticipant] = []
    public var receiptImageData: Data?
    public var validationError: String?

    public let group: Group
    public let currentUserId: String
    private let calculator = BalanceCalculator()
    private let receiptStorage = ReceiptStorageService.shared

    public init(group: Group, currentUserId: String) {
        self.group = group
        self.currentUserId = currentUserId
        self.currency = group.defaultCurrency
        self.paidById = currentUserId
        self.participants = group.members.map { SplitParticipant(userId: $0.id, shareValue: 1) }
    }

    public var amountDecimal: Decimal? {
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: clean)
    }

    public func validateAndBuildExpense() -> Expense? {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Por favor ingresá una descripción."
            return nil
        }

        guard let amount = amountDecimal, amount > 0 else {
            validationError = "Por favor ingresá un monto válido mayor a 0."
            return nil
        }

        do {
            let computed = try calculator.computeParticipantShares(
                totalAmount: amount,
                splitType: splitType,
                participants: participants,
                paidById: paidById
            )

            let expenseId = UUID().uuidString
            var savedReceiptURL: URL? = nil

            if let data = receiptImageData {
                savedReceiptURL = try? receiptStorage.saveReceiptData(data, expenseId: expenseId)
            }

            validationError = nil
            return Expense(
                id: expenseId,
                groupId: group.id,
                description: description,
                amount: amount,
                currency: currency,
                category: category,
                paidById: paidById,
                splitType: splitType,
                participants: computed,
                receiptUrl: savedReceiptURL
            )
        } catch {
            validationError = error.localizedDescription
            return nil
        }
    }
}
