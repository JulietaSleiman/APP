import Foundation
import UserNotifications

@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()

    public private(set) var isAuthorized: Bool = false

    private init() {}

    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            self.isAuthorized = granted
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            self.isAuthorized = false
            return false
        }
    }

    public func notifyNewExpense(description: String, amount: Decimal, currency: Currency, groupName: String, payerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Nuevo Gasto en \(groupName)"
        content.body = "\(payerName) agregó: \(description) por \(currency.symbol)\(amount.formatted())."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    public func notifySettlement(payerName: String, amount: Decimal, currency: Currency, groupName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pago Registrado en \(groupName)"
        content.body = "\(payerName) registró un pago de \(currency.symbol)\(amount.formatted())."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    public func scheduleDebtReminder(groupName: String, amount: Decimal, currency: Currency, inHours hours: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de Balance - SplitWallet"
        content.body = "Tenés una deuda pendiente de \(currency.symbol)\(amount.formatted()) en \(groupName)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, hours * 3600), repeats: false)
        let request = UNNotificationRequest(identifier: "reminder_\(groupName)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
