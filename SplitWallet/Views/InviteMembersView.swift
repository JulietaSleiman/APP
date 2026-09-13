import SwiftUI

public struct InviteMembersView: View {
    @Environment(\.dismiss) private var dismiss
    public let group: Group
    @State private var invite: GroupInvite
    @State private var copiedToClipboard = false

    public init(group: Group) {
        self.group = group
        let code = GroupInvite.generateRandomCode()
        _invite = State(initialValue: GroupInvite(groupId: group.id, inviteCode: code))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Ilustración / Icono
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 20)

                VStack(spacing: 6) {
                    Text("Invitar a \(group.name)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Compartí este código o enlace con las personas que van a compartir gastos.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Código en tarjeta destacada
                VStack(spacing: 12) {
                    Text("CÓDIGO DE INVITACIÓN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text(invite.inviteCode)
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .foregroundColor(.primary)

                    Button {
                        UIPasteboard.general.string = invite.inviteCode
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        withAnimation {
                            copiedToClipboard = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                copiedToClipboard = false
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            Text(copiedToClipboard ? "¡Copiado!" : "Copiar Código")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(copiedToClipboard ? Color.green.opacity(0.15) : Color(uiColor: .tertiarySystemFill))
                        .foregroundColor(copiedToClipboard ? .green : .primary)
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 20)

                Spacer()

                // Botón Compartir Enlace
                ShareLink(
                    item: invite.inviteURL,
                    subject: Text("Unite al grupo \(group.name) en SplitWallet"),
                    message: Text("¡Hola! Unite a \(group.name) para compartir gastos en SplitWallet. Usá el código \(invite.inviteCode) o ingresá al siguiente enlace:")
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir Link")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Invitar Miembros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}
