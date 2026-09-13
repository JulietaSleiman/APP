import XCTest
@testable import SplitWallet

final class CrossGroupBalanceTests: XCTestCase {
    var userMe: User!
    var userMale: User!
    var userPedro: User!

    override func setUp() {
        super.setUp()
        userMe = User(id: "usr_me", name: "Juan", email: "juan@test.com")
        userMale = User(id: "usr_male", name: "Male", email: "male@test.com")
        userPedro = User(id: "usr_pedro", name: "Pedro", email: "pedro@test.com")
    }

    // MARK: - Test 1: Cross-Group Consolidation (Same Currency)

    func testCrossGroupSummary_AggregatesProperlyAcrossMultipleGroups() {
        let viewModel = GroupListViewModel(currentUserId: userMe.id)

        // Grupo 1: Le deben 1500 ARS
        let balanceGroup1 = GroupCurrencyBalance(
            currency: .ARS,
            netBalances: [
                MemberNetBalance(userId: userMe.id, currency: .ARS, netAmount: Decimal(1500)),
                MemberNetBalance(userId: userMale.id, currency: .ARS, netAmount: Decimal(-1500))
            ],
            simplifiedDebts: [
                SimplifiedDebt(fromUserId: userMale.id, toUserId: userMe.id, amount: Decimal(1500), currency: .ARS)
            ]
        )

        // Grupo 2: El usuario debe 500 ARS
        let balanceGroup2 = GroupCurrencyBalance(
            currency: .ARS,
            netBalances: [
                MemberNetBalance(userId: userMe.id, currency: .ARS, netAmount: Decimal(-500)),
                MemberNetBalance(userId: userPedro.id, currency: .ARS, netAmount: Decimal(500))
            ],
            simplifiedDebts: [
                SimplifiedDebt(fromUserId: userMe.id, toUserId: userPedro.id, amount: Decimal(500), currency: .ARS)
            ]
        )

        viewModel.setGroupBalance(groupId: "grp_1", balances: [.ARS: balanceGroup1])
        viewModel.setGroupBalance(groupId: "grp_2", balances: [.ARS: balanceGroup2])

        let summaries = viewModel.computeCrossGroupSummaries()
        guard let arsSummary = summaries[.ARS] else {
            XCTFail("Debe existir resumen para ARS")
            return
        }

        XCTAssertEqual(arsSummary.totalOwedToUser, Decimal(1500), "Te deben 1500 en total")
        XCTAssertEqual(arsSummary.totalUserOwes, Decimal(500), "Debés 500 en total")
        XCTAssertEqual(arsSummary.net, Decimal(1000), "El neto consolidado debe ser +1000")
    }

    // MARK: - Test 2: Cross-Group Consolidation (Multi Currency)

    func testCrossGroupSummary_MultiCurrencySeparation() {
        let viewModel = GroupListViewModel(currentUserId: userMe.id)

        // Grupo 1: Le deben 2000 ARS
        let balanceGroup1 = GroupCurrencyBalance(
            currency: .ARS,
            netBalances: [
                MemberNetBalance(userId: userMe.id, currency: .ARS, netAmount: Decimal(2000))
            ],
            simplifiedDebts: []
        )

        // Grupo 2: El usuario debe 50 USD
        let balanceGroup2 = GroupCurrencyBalance(
            currency: .USD,
            netBalances: [
                MemberNetBalance(userId: userMe.id, currency: .USD, netAmount: Decimal(-50))
            ],
            simplifiedDebts: []
        )

        viewModel.setGroupBalance(groupId: "grp_1", balances: [.ARS: balanceGroup1])
        viewModel.setGroupBalance(groupId: "grp_2", balances: [.USD: balanceGroup2])

        let summaries = viewModel.computeCrossGroupSummaries()

        XCTAssertEqual(summaries.keys.count, 2, "Deben existir 2 divisas independientes en el resumen consolidado")
        XCTAssertEqual(summaries[.ARS]?.net, Decimal(2000))
        XCTAssertEqual(summaries[.USD]?.totalUserOwes, Decimal(50))
        XCTAssertEqual(summaries[.USD]?.net, Decimal(-50))
    }

    // MARK: - Test 3: Direct Settlement Effect in GroupDetailViewModel

    func testSettlementDirectFlow_CancelsPendingDebts() {
        let group = Group(
            id: "grp_01",
            name: "Depto",
            defaultCurrency: .ARS,
            members: [userMe, userMale]
        )

        let detailVM = GroupDetailViewModel(group: group, currentUserId: userMe.id)

        // Gasto inicial: Juan paga $500 compartido a partes iguales con Male
        let initialExpense = Expense(
            groupId: group.id,
            description: "Internet",
            amount: Decimal(500),
            currency: .ARS,
            paidById: userMe.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userMe.id, shareValue: 1),
                SplitParticipant(userId: userMale.id, shareValue: 1)
            ]
        )

        detailVM.addExpenseLocally(initialExpense)

        // Verificamos estado previo al pago
        XCTAssertEqual(detailVM.userNetBalance(for: .ARS), Decimal(250), "A Juan le deben 250")

        // Male le paga $250 a Juan
        let settlement = Settlement(
            groupId: group.id,
            fromUserId: userMale.id,
            toUserId: userMe.id,
            amount: Decimal(250),
            currency: .ARS,
            note: "Transferencia bancaria"
        )

        detailVM.addSettlementLocally(settlement)

        // Verificamos que el balance se recalculó automáticamente a 0
        XCTAssertEqual(detailVM.userNetBalance(for: .ARS), Decimal(0), "La cuenta debe quedar totalmente saldada")
        XCTAssertTrue(detailVM.simplifiedDebts(for: .ARS).isEmpty, "No deben quedar deudas pendientes")
    }
}
