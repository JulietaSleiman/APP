import Foundation
import Observation
import AuthenticationServices

@Observable
public final class AuthenticationManager {
    public var currentUser: User?
    public var isAuthenticated: Bool = false
    public var authError: String?

    public init(currentUser: User? = nil) {
        self.currentUser = currentUser
        self.isAuthenticated = currentUser != nil
    }

    // MARK: - Sign in with Apple

    public func handleSignInWithApple(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authError = "Credenciales inválidas de Apple ID."
            return
        }

        let userId = appleIDCredential.user
        let email = appleIDCredential.email ?? "apple_user@splitwallet.app"
        let givenName = appleIDCredential.fullName?.givenName ?? "Usuario"
        let familyName = appleIDCredential.fullName?.familyName ?? ""
        let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)

        let user = User(
            id: userId,
            name: fullName.isEmpty ? "Usuario de Apple" : fullName,
            email: email,
            authMethod: .apple
        )

        self.currentUser = user
        self.isAuthenticated = true
        self.authError = nil
    }

    // MARK: - Email & Password

    public func signInWithEmail(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            authError = "Por favor ingresá un email válido."
            return
        }

        guard password.count >= 6 else {
            authError = "La contraseña debe tener al menos 6 caracteres."
            return
        }

        // Simulación de autenticación exitosa para desarrollo de MVP
        let user = User(
            id: "usr_\(abs(trimmedEmail.hashValue))",
            name: trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "Usuario",
            email: trimmedEmail,
            authMethod: .emailPassword
        )

        self.currentUser = user
        self.isAuthenticated = true
        self.authError = nil
    }

    public func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
