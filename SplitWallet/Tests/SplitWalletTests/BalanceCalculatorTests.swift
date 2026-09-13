import XCTest
@testable import SplitWallet

final class BalanceCalculatorTests: XCTestCase {
    var sut: BalanceCalculator!
    var userA: User!
    var userB: User!
    var userC: User!

    override func setUp() {
        super.setUp()
        sut = BalanceCalculator()
        userA = User(id: "usr_A", name: "Juan", email: "juan@test.com")
        userB = User(id: "usr_B", name: "Male", email: "male@test.com")
        userC = User(id: "usr_C", name: "Pedro", email: "pedro@test.com")
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test 1: Penny remainder in equal split ($100 / 3)

    func testEqualSplitWithPennyRemainder_AssignsSurplusDeterministically() throws {
        let participants = [
            SplitParticipant(userId: userA.id),
            SplitParticipant(userId: userB.id),
            SplitParticipant(userId: userC.id)
        ]

        let computed = try sut.computeParticipantShares(
            totalAmount: Decimal(100),
            splitType: .equal,
            participants: participants,
            paidById: userA.id
        )

        // Suma exacta requerida
        let sum = computed.reduce(Decimal.zero) { $0 + ($1.computedAmount ?? 0) }
        XCTAssertEqual(sum, Decimal(100), "La suma total de las cuotas debe ser exactamente 100.00")

        // El pagador (userA) absorbe el centavo
        let shareA = computed.first(where: { $0.userId == userA.id })?.computedAmount
        let shareB = computed.first(where: { $0.userId == userB.id })?.computedAmount
        let shareC = computed.first(where: { $0.userId == userC.id })?.computedAmount

        XCTAssertEqual(shareA, Decimal(string: "33.34"))
        XCTAssertEqual(shareB, Decimal(string: "33.33"))
        XCTAssertEqual(shareC, Decimal(string: "33.33"))
    }

    // MARK: - Test 2: Net balance between two users

    func testBalanceCalculation_BasicTwoUsers() throws {
        let expense = Expense(
            groupId: "grp_01",
            description: "Cena",
            amount: Decimal(1000),
            currency: .ARS,
            paidById: userA.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id),
                SplitParticipant(userId: userB.id)
            ]
        )

        let result = try sut.calculateBalances(
            members: [userA, userB],
            expenses: [expense],
            settlements: []
        )

        guard let arsBalance = result[.ARS] else {
            XCTFail("Debe existir balance en ARS")
            return
        }

        let netA = arsBalance.netBalances.first(where: { $0.userId == userA.id })?.netAmount
        let netB = arsBalance.netBalances.first(where: { $0.userId == userB.id })?.netAmount

        XCTAssertEqual(netA, Decimal(500), "A debe tener +500 a favor")
        XCTAssertEqual(netB, Decimal(-500), "B debe tener -500 en contra")

        XCTAssertEqual(arsBalance.simplifiedDebts.count, 1)
        XCTAssertEqual(arsBalance.simplifiedDebts.first?.fromUserId, userB.id)
        XCTAssertEqual(arsBalance.simplifiedDebts.first?.toUserId, userA.id)
        XCTAssertEqual(arsBalance.simplifiedDebts.first?.amount, Decimal(500))
    }

    // MARK: - Test 3: Debt simplification (A -> B -> C becomes A -> C)

    func testDebtSimplification_ThreeUsersChainTransfers() throws {
        // Gasto 1: userB paga $100 compartido únicamente con userA (userA le debe $100 a userB)
        let exp1 = Expense(
            groupId: "grp_01",
            description: "Taxi",
            amount: Decimal(100),
            currency: .ARS,
            paidById: userB.id,
            splitType: .exact,
            participants: [
                SplitParticipant(userId: userA.id, shareValue: Decimal(100))
            ]
        )

        // Gasto 2: userC paga $100 compartido únicamente con userB (userB le debe $100 a userC)
        let exp2 = Expense(
            groupId: "grp_01",
            description: "Bebidas",
            amount: Decimal(100),
            currency: .ARS,
            paidById: userC.id,
            splitType: .exact,
            participants: [
                SplitParticipant(userId: userB.id, shareValue: Decimal(100))
            ]
        )

        let result = try sut.calculateBalances(
            members: [userA, userB, userC],
            expenses: [exp1, exp2],
            settlements: []
        )

        let arsBalance = try XCTUnwrap(result[.ARS])

        let netA = arsBalance.netBalances.first(where: { $0.userId == userA.id })?.netAmount
        let netB = arsBalance.netBalances.first(where: { $0.userId == userB.id })?.netAmount
        let netC = arsBalance.netBalances.first(where: { $0.userId == userC.id })?.netAmount

        XCTAssertEqual(netA, Decimal(-100))
        XCTAssertEqual(netB, Decimal(0))
        XCTAssertEqual(netC, Decimal(100))

        // Simplificación: sólo 1 pago necesario, userA paga directo a userC $100
        XCTAssertEqual(arsBalance.simplifiedDebts.count, 1)
        let debt = try XCTUnwrap(arsBalance.simplifiedDebts.first)
        XCTAssertEqual(debt.fromUserId, userA.id)
        XCTAssertEqual(debt.toUserId, userC.id)
        XCTAssertEqual(debt.amount, Decimal(100))
    }

    // MARK: - Test 4: Multi-currency segregation

    func testMultiCurrencySegregation() throws {
        let expenseARS = Expense(
            groupId: "grp_01",
            description: "Café en BsAs",
            amount: Decimal(3000),
            currency: .ARS,
            paidById: userA.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id),
                SplitParticipant(userId: userB.id)
            ]
        )

        let expenseUSD = Expense(
            groupId: "grp_01",
            description: "Hotel en Miami",
            amount: Decimal(200),
            currency: .USD,
            paidById: userB.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id),
                SplitParticipant(userId: userB.id)
            ]
        )

        let result = try sut.calculateBalances(
            members: [userA, userB],
            expenses: [expenseARS, expenseUSD],
            settlements: []
        )

        XCTAssertEqual(result.keys.count, 2, "Debe haber 2 balances separados")

        let ars = try XCTUnwrap(result[.ARS])
        let usd = try XCTUnwrap(result[.USD])

        XCTAssertEqual(ars.netBalances.first(where: { $0.userId == userA.id })?.netAmount, Decimal(1500))
        XCTAssertEqual(usd.netBalances.first(where: { $0.userId == userB.id })?.netAmount, Decimal(100))
    }

    // MARK: - Test 5: Settlement application

    func testSettlementRestoresZeroBalance() throws {
        let expense = Expense(
            groupId: "grp_01",
            description: "Comida",
            amount: Decimal(200),
            currency: .ARS,
            paidById: userA.id,
            splitType: .equal,
            participants: [
                SplitParticipant(userId: userA.id),
                SplitParticipant(userId: userB.id)
            ]
        )

        let settlement = Settlement(
            groupId: "grp_01",
            fromUserId: userB.id,
            toUserId: userA.id,
            amount: Decimal(100),
            currency: .ARS
        )

        let result = try sut.calculateBalances(
            members: [userA, userB],
            expenses: [expense],
            settlements: [settlement]
        )

        let ars = try XCTUnwrap(result[.ARS])
        let netA = ars.netBalances.first(where: { $0.userId == userA.id })?.netAmount
        let netB = ars.netBalances.first(where: { $0.userId == userB.id })?.netAmount

        XCTAssertEqual(netA, Decimal(0))
        XCTAssertEqual(netB, Decimal(0))
        XCTAssertTrue(ars.simplifiedDebts.isEmpty, "No deben quedar deudas pendientes tras liquidación")
    }
}
