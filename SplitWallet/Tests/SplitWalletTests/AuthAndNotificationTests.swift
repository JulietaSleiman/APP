import XCTest
@testable import SplitWallet

final class AuthAndNotificationTests: XCTestCase {

    // MARK: - Test 1: Group Invite Code Generation & URL Formatting

    func testGroupInviteCodeGeneration_LengthAndURL() {
        let code = GroupInvite.generateRandomCode()
        XCTAssertEqual(code.count, 6, "El código de invitación debe tener 6 caracteres")

        // No debe contener caracteres confusos visualmente
        let confusingChars: Set<Character> = ["0", "O", "1", "I"]
        for char in code {
            XCTAssertFalse(confusingChars.contains(char), "El código no debe incluir el caracter ambiguo \(char)")
        }

        let invite = GroupInvite(groupId: "grp_123", inviteCode: code)
        XCTAssertEqual(invite.inviteURL.absoluteString, "https://splitwallet.app/join/\(code)")
    }

    // MARK: - Test 2: Authentication Validation (Email & Password)

    func testEmailPasswordAuthentication_ValidationFlow() {
        let authManager = AuthenticationManager()

        // Caso 1: Email inválido
        authManager.signInWithEmail(email: "email-invalido", password: "password123")
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.authError)

        // Caso 2: Contraseña demasiado corta
        authManager.signInWithEmail(email: "user@test.com", password: "123")
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.authError)

        // Caso 3: Credenciales válidas
        authManager.signInWithEmail(email: "user@test.com", password: "passwordSeguro123")
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNil(authManager.authError)
        XCTAssertEqual(authManager.currentUser?.email, "user@test.com")
        XCTAssertEqual(authManager.currentUser?.authMethod, .emailPassword)

        // Caso 4: Sign out
        authManager.signOut()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
    }

    // MARK: - Test 3: Notification Payload Integrity

    func testNotificationPayloadCreation() {
        let payload = AppNotificationPayload(
            type: .expenseCreated,
            groupId: "grp_bariloche",
            groupName: "Viaje a Bariloche",
            title: "Nuevo Gasto en Bariloche",
            body: "Juan pagó Almuerzo por $3500",
            targetUserId: "usr_male",
            amount: Decimal(3500),
            currency: .ARS
        )

        XCTAssertEqual(payload.type, .expenseCreated)
        XCTAssertEqual(payload.groupName, "Viaje a Bariloche")
        XCTAssertEqual(payload.amount, Decimal(3500))
        XCTAssertEqual(payload.currency, .ARS)
        XCTAssertEqual(payload.targetUserId, "usr_male")
    }
}
