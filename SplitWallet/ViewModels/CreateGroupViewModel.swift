import Foundation
import Observation

@Observable
public final class CreateGroupViewModel {
    public var name: String = ""
    public var defaultCurrency: Currency = .ARS
    public var newMemberName: String = ""
    public var newMemberEmail: String = ""
    public var members: [User] = []
    public var validationError: String?

    public let currentUser: User

    public init(currentUser: User) {
        self.currentUser = currentUser
        self.members = [currentUser]
    }

    public func addMember() {
        let trimmedName = newMemberName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationError = "Ingresá un nombre para el miembro."
            return
        }

        let user = User(
            name: trimmedName,
            email: newMemberEmail.trimmingCharacters(in: .whitespaces)
        )
        members.append(user)
        newMemberName = ""
        newMemberEmail = ""
        validationError = nil
    }

    public func removeMember(at index: Int) {
        guard index < members.count else { return }
        // No permitir borrar al creador actual
        if members[index].id == currentUser.id { return }
        members.remove(at: index)
    }

    public func buildGroup() -> Group? {
        let trimmedTitle = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            validationError = "Por favor ingresá un nombre para el grupo."
            return nil
        }

        guard members.count >= 2 else {
            validationError = "El grupo debe tener al menos 2 miembros para compartir gastos."
            return nil
        }

        validationError = nil
        return Group(
            name: trimmedTitle,
            defaultCurrency: defaultCurrency,
            members: members
        )
    }
}
