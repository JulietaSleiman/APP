import Foundation
import Observation

public struct CrossGroupBalanceSummary: Sendable {
    public let currency: Currency
    public let totalOwedToUser: Decimal
    public let totalUserOwes: Decimal

    public var net: Decimal {
        totalOwedToUser - totalUserOwes
    }
}

@Observable
public final class GroupListViewModel {
    public var groups: [Group] = []
    public var currentUserId: String
    public var isLoading: Bool = false
    public var errorMessage: String?

    // Balances calculados por cada grupo
    public var groupBalances: [String: [Currency: GroupCurrencyBalance]] = [:]

    private let balanceCalculator: BalanceCalculator
    private let localStorage: LocalStorageRepository?

    public init(
        currentUserId: String,
        balanceCalculator: BalanceCalculator = BalanceCalculator(),
        localStorage: LocalStorageRepository? = nil
    ) {
        self.currentUserId = currentUserId
        self.balanceCalculator = balanceCalculator
        self.localStorage = localStorage
    }

    public func loadData() {
        if let local = localStorage {
            self.groups = local.fetchGroups()
        }
    }

    public func setGroupBalance(groupId: String, balances: [Currency: GroupCurrencyBalance]) {
        groupBalances[groupId] = balances
    }

    public func netBalance(for group: Group) -> Decimal {
        guard let currencyBalance = groupBalances[group.id]?[group.defaultCurrency] else {
            return .zero
        }
        return currencyBalance.netBalances.first(where: { $0.userId == currentUserId })?.netAmount ?? .zero
    }

    // MARK: - Resumen Personal Cross-Grupo

    public func computeCrossGroupSummaries() -> [Currency: CrossGroupBalanceSummary] {
        var results: [Currency: (owedToUser: Decimal, userOwes: Decimal)] = [:]

        for (_, balances) in groupBalances {
            for (currency, groupCurrencyBalance) in balances {
                guard let userBalance = groupCurrencyBalance.netBalances.first(where: { $0.userId == currentUserId }) else {
                    continue
                }

                var current = results[currency, default: (owedToUser: .zero, userOwes: .zero)]
                if userBalance.netAmount > 0 {
                    current.owedToUser += userBalance.netAmount
                } else if userBalance.netAmount < 0 {
                    current.userOwes += abs(userBalance.netAmount)
                }
                results[currency] = current
            }
        }

        return results.mapValues {
            CrossGroupBalanceSummary(
                currency: $0.key,
                totalOwedToUser: $0.value.owedToUser,
                totalUserOwes: $0.value.userOwes
            )
        }
    }

    public func addGroupLocally(_ group: Group) {
        groups.insert(group, at: 0)
        localStorage?.saveGroup(group)
    }
}
