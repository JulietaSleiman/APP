import XCTest
@testable import SplitWallet

final class ExpenseAuditAndExportTests: XCTestCase {
    var group: Group!
    var userA: User!
    var userB: User!
    var viewModel: GroupDetailViewModel!

    override func setUp() {
        super.setUp()
        userA = User(id: "usr_A", name: "Juan", email: "juan@test.com")
        userB = User(id: "usr_B", name: "Male", email: "male@test.com")
        group = Group(
            id: "grp_test",
            name: "Depto Test",
            defaultCurrency: .ARS,
            members: [userA, userB]
        )
        viewModel = GroupDetailViewModel(group: group, currentUserId: userA.id)
    }

    override func tearDown() {
        viewModel = nil
        group = nil
        userA = nil
        userB = nil
        super.tearDown()
    }

    // MARK: - Test 1: Expense Edit recalibrates balance and keeps audit trail

    func testExpenseModification_UpdatesBalanceAndRecordsAuditLog() {
        let initialExpense = Expense(
            id: "exp_01",
            groupId: group.id,
            description: "Supermercado",
            amount: Decimal(100),
            currency: .ARS,
            paidById: userA.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id, shareValue: 1, computedAmount: Decimal(50)),
                SplitParticipant(userId: userB.id, shareValue: 1, computedAmount: Decimal(50))
            ]
        )

        viewModel.addExpenseLocally(initialExpense)

        // Estado inicial
        XCTAssertEqual(viewModel.userNetBalance(for: .ARS), Decimal(50))
        XCTAssertEqual(viewModel.auditLogs(for: "exp_01").count, 1)
        XCTAssertEqual(viewModel.auditLogs(for: "exp_01").first?.action, .created)

        // Modificamos a $200
        var updatedExpense = initialExpense
        updatedExpense.amount = Decimal(200)
        updatedExpense.participants = [
            SplitParticipant(userId: userA.id, shareValue: 1, computedAmount: Decimal(100)),
            SplitParticipant(userId: userB.id, shareValue: 1, computedAmount: Decimal(100))
        ]

        viewModel.updateExpenseLocally(updatedExpense, modifiedBy: userA.id)

        // Balance recalculado automáticamente a 100
        XCTAssertEqual(viewModel.userNetBalance(for: .ARS), Decimal(100))

        // Auditoría
        let logs = viewModel.auditLogs(for: "exp_01")
        XCTAssertEqual(logs.count, 2)
        let latestLog = logs.first
        XCTAssertEqual(latestLog?.action, .updated)
        XCTAssertEqual(latestLog?.previousAmount, Decimal(100))
        XCTAssertEqual(latestLog?.newAmount, Decimal(200))
    }

    // MARK: - Test 2: Expense Deletion recalibrates balance

    func testExpenseDeletion_RestoresZeroBalanceAndRecordsAuditLog() {
        let expense = Expense(
            id: "exp_02",
            groupId: group.id,
            description: "Farmacia",
            amount: Decimal(80),
            currency: .ARS,
            paidById: userA.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id, shareValue: 1, computedAmount: Decimal(40)),
                SplitParticipant(userId: userB.id, shareValue: 1, computedAmount: Decimal(40))
            ]
        )

        viewModel.addExpenseLocally(expense)
        XCTAssertEqual(viewModel.userNetBalance(for: .ARS), Decimal(40))

        viewModel.deleteExpenseLocally(id: "exp_02", modifiedBy: userB.id)

        XCTAssertEqual(viewModel.userNetBalance(for: .ARS), Decimal(0), "Al borrar el gasto el balance debe ser 0")
        XCTAssertTrue(viewModel.expenses.isEmpty)

        let logs = viewModel.auditLogs(for: "exp_02")
        XCTAssertEqual(logs.first?.action, .deleted)
        XCTAssertEqual(logs.first?.modifiedByUserId, userB.id)
    }

    // MARK: - Test 3: CSV Report Structure & RFC 4180 Escaping

    func testCSVReportGeneration_ContainsAllSectionsAndEscapesCommas() {
        let expense = Expense(
            id: "exp_03",
            groupId: group.id,
            description: "Cena, vino y postre", // Contiene comas intencionales
            amount: Decimal(150),
            currency: .ARS,
            paidById: userA.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id, shareValue: 1, computedAmount: Decimal(75)),
                SplitParticipant(userId: userB.id, shareValue: 1, computedAmount: Decimal(75))
            ]
        )

        viewModel.addExpenseLocally(expense)
        let csv = viewModel.generateCSVExport()

        // Verifica BOM UTF-8
        XCTAssertTrue(csv.hasPrefix("\u{FEFF}"), "Debe incluir BOM UTF-8 para Excel")

        // Verifica Secciones
        XCTAssertTrue(csv.contains("--- BALANCES NETOS POR MONEDA ---"))
        XCTAssertTrue(csv.contains("--- DEUDAS SIMPLIFICADAS (QUIÉN LE DEBE A QUIÉN) ---"))
        XCTAssertTrue(csv.contains("--- HISTORIAL DETALLADO DE GASTOS ---"))
        XCTAssertTrue(csv.contains("--- HISTORIAL DE LIQUIDACIONES / PAGOS ---"))

        // Verifica escape de comas en descripción
        XCTAssertTrue(csv.contains("\"Cena, vino y postre\""), "La descripción con comas debe estar entre comillas")
    }
}
