import Foundation

public final class BalanceCalculator: Sendable {

    public init() {}

    // MARK: - Split Breakdown Calculation

    /// Calcula la cuota exacta para cada participante garantizando que la suma sea exactamente igual al total del gasto.
    /// Si hay centavos sobrantes por división inexacta (ej. $100 / 3 = 33.33 c/u con 0.01 sobrante),
    /// la regla asigna el centavo sobrante al pagador si participa, o al primer participante según orden determinista de ID.
    public func computeParticipantShares(
        totalAmount: Decimal,
        splitType: SplitType,
        participants: [SplitParticipant],
        paidById: String
    ) throws -> [SplitParticipant] {
        guard !participants.isEmpty else {
            return []
        }

        switch splitType {
        case .equal:
            return computeEqualSplit(totalAmount: totalAmount, participants: participants, paidById: paidById)

        case .exact:
            let sumExact = participants.reduce(Decimal.zero) { $0 + $1.shareValue }
            guard sumExact == totalAmount else {
                throw SplitError.exactAmountsDoNotMatchTotal(expected: totalAmount, actual: sumExact)
            }
            return participants.map { p in
                var updated = p
                updated.computedAmount = p.shareValue
                return updated
            }

        case .percentage:
            let sumPercentage = participants.reduce(Decimal.zero) { $0 + $1.shareValue }
            guard abs(sumPercentage - 100) < 0.001 else {
                throw SplitError.percentagesMustEqual100(actual: sumPercentage)
            }
            return computePercentageSplit(totalAmount: totalAmount, participants: participants, paidById: paidById)

        case .shares:
            let totalShares = participants.reduce(Decimal.zero) { $0 + $1.shareValue }
            guard totalShares > 0 else {
                throw SplitError.invalidTotalShares
            }
            return computeSharesSplit(totalAmount: totalAmount, totalShares: totalShares, participants: participants, paidById: paidById)
        }
    }

    private func computeEqualSplit(
        totalAmount: Decimal,
        participants: [SplitParticipant],
        paidById: String
    ) -> [SplitParticipant] {
        let count = Decimal(participants.count)
        var basePerPerson = (totalAmount / count)
        var roundedBase = Decimal()
        var baseToRound = basePerPerson
        NSDecimalRound(&roundedBase, &baseToRound, 2, .down)

        let allocated = roundedBase * count
        let remainder = totalAmount - allocated
        var remainderCents = Int((remainder * 100).description) ?? 0

        // Prioridad de absorción de centavos: el pagador primero, luego orden por userId
        let sortedParticipants = participants.sorted { a, b in
            if a.userId == paidById { return true }
            if b.userId == paidById { return false }
            return a.userId < b.userId
        }

        var results: [SplitParticipant] = []
        for p in sortedParticipants {
            var share = roundedBase
            if remainderCents > 0 {
                share += Decimal(string: "0.01")!
                remainderCents -= 1
            }
            var item = p
            item.computedAmount = share
            results.append(item)
        }

        // Mantener orden original
        return participants.compactMap { original in
            results.first(where: { $0.userId == original.userId })
        }
    }

    private func computePercentageSplit(
        totalAmount: Decimal,
        participants: [SplitParticipant],
        paidById: String
    ) -> [SplitParticipant] {
        var computedItems: [SplitParticipant] = []
        var totalAllocated = Decimal.zero

        for p in participants {
            let exactShare = (totalAmount * p.shareValue) / 100
            var rounded = Decimal()
            var shareToRound = exactShare
            NSDecimalRound(&rounded, &shareToRound, 2, .plain)
            var item = p
            item.computedAmount = rounded
            totalAllocated += rounded
            computedItems.append(item)
        }

        let diff = totalAmount - totalAllocated
        if diff != 0 {
            // Ajustar diferencia de centavos al pagador o al primer participante
            let targetId = participants.contains(where: { $0.userId == paidById }) ? paidById : participants[0].userId
            if let index = computedItems.firstIndex(where: { $0.userId == targetId }) {
                computedItems[index].computedAmount = (computedItems[index].computedAmount ?? 0) + diff
            }
        }

        return computedItems
    }

    private func computeSharesSplit(
        totalAmount: Decimal,
        totalShares: Decimal,
        participants: [SplitParticipant],
        paidById: String
    ) -> [SplitParticipant] {
        var computedItems: [SplitParticipant] = []
        var totalAllocated = Decimal.zero

        for p in participants {
            let exactShare = (totalAmount * p.shareValue) / totalShares
            var rounded = Decimal()
            var shareToRound = exactShare
            NSDecimalRound(&rounded, &shareToRound, 2, .down)
            var item = p
            item.computedAmount = rounded
            totalAllocated += rounded
            computedItems.append(item)
        }

        let diff = totalAmount - totalAllocated
        var remainderCents = Int((diff * 100).description) ?? 0

        let sorted = computedItems.sorted { a, b in
            if a.userId == paidById { return true }
            if b.userId == paidById { return false }
            return a.userId < b.userId
        }

        var adjustedMap: [String: Decimal] = [:]
        for item in sorted {
            var amount = item.computedAmount ?? 0
            if remainderCents > 0 {
                amount += Decimal(string: "0.01")!
                remainderCents -= 1
            }
            adjustedMap[item.userId] = amount
        }

        return participants.map { original in
            var updated = original
            updated.computedAmount = adjustedMap[original.userId] ?? 0
            return updated
        }
    }

    // MARK: - Balance & Debt Calculation

    /// Calcula los balances netos y simplifica las deudas separadas estrictamente por moneda
    public func calculateBalances(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement]
    ) throws -> [Currency: GroupCurrencyBalance] {
        // Identificar todas las monedas presentes
        var currencies: Set<Currency> = Set(expenses.map(\.currency))
        currencies.formUnion(settlements.map(\.currency))

        var results: [Currency: GroupCurrencyBalance] = [:]

        for currency in currencies {
            let currencyExpenses = expenses.filter { $0.currency == currency }
            let currencySettlements = settlements.filter { $0.currency == currency }

            var netMap: [String: Decimal] = [:]
            for member in members {
                netMap[member.id] = Decimal.zero
            }

            // Procesar gastos
            for expense in currencyExpenses {
                let computedParts = try computeParticipantShares(
                    totalAmount: expense.amount,
                    splitType: expense.splitType,
                    participants: expense.participants,
                    paidById: expense.paidById
                )

                // El pagador suma el total
                netMap[expense.paidById, default: 0] += expense.amount

                // Cada participante resta su cuota
                for part in computedParts {
                    let share = part.computedAmount ?? 0
                    netMap[part.userId, default: 0] -= share
                }
            }

            // Procesar liquidaciones (settlements)
            for settlement in currencySettlements {
                // fromUser pagó, por ende aumenta su crédito neto / salda su deuda
                netMap[settlement.fromUserId, default: 0] += settlement.amount
                // toUser recibió, por ende disminuye su crédito neto
                netMap[settlement.toUserId, default: 0] -= settlement.amount
            }

            let memberNetBalances: [MemberNetBalance] = netMap.map { userId, net in
                MemberNetBalance(userId: userId, currency: currency, netAmount: net)
            }.sorted { $0.userId < $1.userId }

            let simplifiedDebts = simplifyDebts(netMap: netMap, currency: currency)

            results[currency] = GroupCurrencyBalance(
                currency: currency,
                netBalances: memberNetBalances,
                simplifiedDebts: simplifiedDebts
            )
        }

        return results
    }

    // MARK: - Greedy Debt Simplification Algorithm

    private func simplifyDebts(netMap: [String: Decimal], currency: Currency) -> [SimplifiedDebt] {
        // Separar deudores (net < 0) y acreedores (net > 0)
        var debtors: [(userId: String, amount: Decimal)] = []
        var creditors: [(userId: String, amount: Decimal)] = []

        for (userId, net) in netMap {
            if net < -0.001 {
                debtors.append((userId: userId, amount: abs(net)))
            } else if net > 0.001 {
                creditors.append((userId: userId, amount: net))
            }
        }

        var simplified: [SimplifiedDebt] = []

        var debtorIndex = 0
        var creditorIndex = 0

        while debtorIndex < debtors.count && creditorIndex < creditors.count {
            debtors.sort { $0.amount > $1.amount }
            creditors.sort { $0.amount > $1.amount }

            let debtor = debtors[debtorIndex]
            let creditor = creditors[creditorIndex]

            let transferAmount = min(debtor.amount, creditor.amount)

            if transferAmount > 0.001 {
                simplified.append(
                    SimplifiedDebt(
                        fromUserId: debtor.userId,
                        toUserId: creditor.userId,
                        amount: transferAmount,
                        currency: currency
                    )
                )
            }

            debtors[debtorIndex].amount -= transferAmount
            creditors[creditorIndex].amount -= transferAmount

            if debtors[debtorIndex].amount < 0.001 {
                debtorIndex += 1
            }
            if creditors[creditorIndex].amount < 0.001 {
                creditorIndex += 1
            }
        }

        return simplified
    }
}

public enum SplitError: LocalizedError {
    case exactAmountsDoNotMatchTotal(expected: Decimal, actual: Decimal)
    case percentagesMustEqual100(actual: Decimal)
    case invalidTotalShares

    public var errorDescription: String? {
        switch self {
        case .exactAmountsDoNotMatchTotal(let expected, let actual):
            return "La suma de montos exactos (\(actual)) no coincide con el total (\(expected))."
        case .percentagesMustEqual100(let actual):
            return "La suma de porcentajes debe ser exactamente 100% (actual: \(actual)%)."
        case .invalidTotalShares:
            return "El total de partes debe ser mayor a 0."
        }
    }
}
