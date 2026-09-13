import Foundation

public final class GroupReportExporter: Sendable {

    public init() {}

    /// Genera un documento CSV completo con el resumen del grupo, balances y detalle de transacciones
    public func generateCSVReport(
        group: Group,
        expenses: [Expense],
        settlements: [Settlement],
        balances: [Currency: GroupCurrencyBalance]
    ) -> String {
        var csv = "\u{FEFF}" // BOM UTF-8 para visualización correcta en Excel/Numbers
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        // Cabecera del Reporte
        csv.append("REPORTE DE GASTOS Y BALANCES - SPLITWALLET\n")
        csv.append("Grupo:,\(escapeCSV(group.name))\n")
        csv.append("Fecha de Generación:,\(dateFormatter.string(from: Date()))\n")
        csv.append("Moneda Principal:,\(group.defaultCurrency.rawValue)\n")
        csv.append("Total Miembros:,\(group.members.count)\n\n")

        // SECCIÓN 1: BALANCES NETOS
        csv.append("--- BALANCES NETOS POR MONEDA ---\n")
        csv.append("Moneda,Miembro,Email,Balance Neto,Estado\n")
        for (currency, currBalance) in balances {
            for memberNet in currBalance.netBalances {
                let member = group.members.first(where: { $0.id == memberNet.userId })
                let name = member?.name ?? "Desconocido"
                let email = member?.email ?? ""
                let status = memberNet.netAmount > 0 ? "Acreedor (le deben)" : (memberNet.netAmount < 0 ? "Deudor (debe)" : "Al día")
                csv.append("\(currency.rawValue),\(escapeCSV(name)),\(escapeCSV(email)),\(memberNet.netAmount),\(status)\n")
            }
        }
        csv.append("\n")

        // SECCIÓN 2: DEUDAS SIMPLIFICADAS
        csv.append("--- DEUDAS SIMPLIFICADAS (QUIÉN LE DEBE A QUIÉN) ---\n")
        csv.append("Moneda,Deudor (Paga),Acreedor (Recibe),Monto a Transferir\n")
        for (currency, currBalance) in balances {
            for debt in currBalance.simplifiedDebts {
                let fromName = group.members.first(where: { $0.id == debt.fromUserId })?.name ?? debt.fromUserId
                let toName = group.members.first(where: { $0.id == debt.toUserId })?.name ?? debt.toUserId
                csv.append("\(currency.rawValue),\(escapeCSV(fromName)),\(escapeCSV(toName)),\(debt.amount)\n")
            }
        }
        csv.append("\n")

        // SECCIÓN 3: HISTORIAL DETALLADO DE GASTOS
        csv.append("--- HISTORIAL DETALLADO DE GASTOS ---\n")
        csv.append("ID,Fecha,Descripción,Categoría,Pagado Por,Monto,Moneda,Tipo de División\n")
        for exp in expenses.sorted(by: { $0.date > $1.date }) {
            let payer = group.members.first(where: { $0.id == exp.paidById })?.name ?? exp.paidById
            csv.append("\(exp.id),\(dateFormatter.string(from: exp.date)),\(escapeCSV(exp.description)),\(exp.category.displayName),\(escapeCSV(payer)),\(exp.amount),\(exp.currency.rawValue),\(exp.splitType.displayName)\n")
        }
        csv.append("\n")

        // SECCIÓN 4: HISTORIAL DE LIQUIDACIONES (PAGOS)
        csv.append("--- HISTORIAL DE LIQUIDACIONES / PAGOS ---\n")
        csv.append("ID,Fecha,De (Pagó),Para (Recibió),Monto,Moneda,Nota\n")
        for s in settlements.sorted(by: { $0.date > $1.date }) {
            let fromName = group.members.first(where: { $0.id == s.fromUserId })?.name ?? s.fromUserId
            let toName = group.members.first(where: { $0.id == s.toUserId })?.name ?? s.toUserId
            csv.append("\(s.id),\(dateFormatter.string(from: s.date)),\(escapeCSV(fromName)),\(escapeCSV(toName)),\(s.amount),\(s.currency.rawValue),\(escapeCSV(s.note ?? ""))\n")
        }

        return csv
    }

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let replaced = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(replaced)\""
        }
        return field
    }
}
