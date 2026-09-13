import XCTest
@testable import SplitWallet

final class ReceiptStorageTests: XCTestCase {
    var sut: ReceiptStorageService!
    var createdURLs: [URL] = []

    override func setUp() {
        super.setUp()
        sut = ReceiptStorageService()
    }

    override func tearDown() {
        for url in createdURLs {
            sut.deleteReceipt(at: url)
        }
        createdURLs.removeAll()
        sut = nil
        super.tearDown()
    }

    // MARK: - Test 1: Save & Load Receipt Data

    func testSaveAndLoadReceiptData_SavesSuccessfullyAndMatchesBytes() throws {
        let dummyData = "DUMMY_RECEIPT_IMAGE_DATA".data(using: .utf8)!
        let expenseId = "exp_test_receipt"

        let fileURL = try sut.saveReceiptData(dummyData, expenseId: expenseId)
        createdURLs.append(fileURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let loadedData = sut.loadReceiptData(from: fileURL)
        XCTAssertNotNil(loadedData)
        XCTAssertEqual(loadedData, dummyData, "Los datos guardados y cargados deben ser idénticos")
    }

    // MARK: - Test 2: Delete Receipt Data

    func testDeleteReceipt_RemovesFileFromDisk() throws {
        let dummyData = "DATA_TO_DELETE".data(using: .utf8)!
        let fileURL = try sut.saveReceiptData(dummyData, expenseId: "exp_delete")

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        sut.deleteReceipt(at: fileURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path), "El archivo no debe existir tras borrarlo")
    }
}
