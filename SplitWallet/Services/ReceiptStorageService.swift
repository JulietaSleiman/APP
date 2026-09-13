import Foundation

public final class ReceiptStorageService: Sendable {
    public static let shared = ReceiptStorageService()

    private let fileManager = FileManager.default
    private let directoryName = "Receipts"

    public init() {
        createReceiptsDirectoryIfNeeded()
    }

    private var receiptsDirectoryURL: URL {
        let documents = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        return documents.appendingPathComponent(directoryName, isDirectory: true)
    }

    private func createReceiptsDirectoryIfNeeded() {
        let url = receiptsDirectoryURL
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Guarda los datos binarios de la imagen de un ticket y devuelve su URL persistente
    public func saveReceiptData(_ data: Data, expenseId: String) throws -> URL {
        createReceiptsDirectoryIfNeeded()
        let filename = "\(expenseId)_\(UUID().uuidString).jpg"
        let fileURL = receiptsDirectoryURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    /// Carga los datos binarios del ticket desde la URL del archivo
    public func loadReceiptData(from fileURL: URL) -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// Elimina el archivo de imagen de disco
    public func deleteReceipt(at fileURL: URL) {
        try? fileManager.removeItem(at: fileURL)
    }
}
