import Foundation
import Observation

@Observable
public final class RecordSettlementViewModel {
    public var fromUserId: String
    public var toUserId: String
    public var amountString: String = ""
    public var currency: Currency
    public var note: String = ""
    public var validationError: String?

    public let group: Group

    public init(group: Group, defaultFrom: String, defaultTo: String? = nil, defaultAmount: Decimal? = nil) {
        self.group = group
        self.currency = group.defaultCurrency
        self.fromUserId = defaultFrom
        self.toUserId = defaultTo ?? group.members.first(where: { $0.id != defaultFrom })?.id ?? ""
        if let amount = defaultAmount {
            self.amountString = amount.formatted()
        }
    }

    public var amountDecimal: Decimal? {
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: clean)
    }

    public func buildSettlement() -> Settlement? {
        guard fromUserId != toUserId else {
            validationError = "El pagador y el receptor no pueden ser la misma persona."
            return nil
        }

        guard let amount = amountDecimal, amount > 0 else {
            validationError = "Ingresá un monto mayor a 0."
            return nil
        }

        validationError = nil
        return Settlement(
            groupId: group.id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            currency: currency,
            note: note.isEmpty ? nil : note
        )
    }
}
