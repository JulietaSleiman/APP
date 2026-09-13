import SwiftUI
import AuthenticationServices

public struct AuthView: View {
    @Bindable public var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailForm = false

    public init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }

    public var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Branding
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                }

                Text("SplitWallet")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Cuentas claras y finanzas compartidas sin complicaciones.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Botones de Autenticación
            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        authManager.handleSignInWithApple(authorization: authorization)
                    case .failure(let error):
                        authManager.authError = error.localizedDescription
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)

                if showEmailForm {
                    VStack(spacing: 10) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(uiColor: .secondarySystemFill))
                            .cornerRadius(10)

                        SecureField("Contraseña", text: $password)
                            .padding()
                            .background(Color(uiColor: .secondarySystemFill))
                            .cornerRadius(10)

                        Button {
                            authManager.signInWithEmail(email: email, password: password)
                        } label: {
                            Text("Ingresar")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Button {
                        withAnimation(.spring) {
                            showEmailForm = true
                        }
                    } label: {
                        Text("Continuar con Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 6)
                }

                if let error = authManager.authError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
