import XCTest
@testable import KilatRunner

@MainActor
final class BankAccountsViewModelTests: XCTestCase {
    func test_add_appendsAndSetsDefault_ifFirstAccount() async {
        let repository = BankAccountsRepositorySpy()
        let viewModel = BankAccountsViewModel(repository: repository)

        await viewModel.add(BankAccountDraft(bankName: "Maybank", accountNumber: "1234567890", holderName: "Luqman"))

        XCTAssertEqual(viewModel.accounts.count, 1)
        XCTAssertTrue(viewModel.accounts[0].isDefault)
        XCTAssertEqual(repository.addedDrafts.first?.bankName, "Maybank")
    }

    func test_deleteDefault_returns_displaysServerError() async {
        let account = BankAccount(id: "bank-1", bankName: "CIMB", holderName: "Luqman", accountNumberLast4: "4521", isDefault: true)
        let repository = BankAccountsRepositorySpy(accounts: [account], deleteError: NetworkError.serverError(500))
        let viewModel = BankAccountsViewModel(repository: repository)
        await viewModel.load()

        await viewModel.delete(id: account.id)

        XCTAssertEqual(viewModel.accounts, [account])
        XCTAssertEqual(viewModel.errorMessage, NetworkError.serverError(500).userMessage)
    }
}

private final class BankAccountsRepositorySpy: BankAccountsRepositoryProtocol {
    var accounts: [BankAccount]
    var addedDrafts: [BankAccountDraft] = []
    let deleteError: Error?

    init(accounts: [BankAccount] = [], deleteError: Error? = nil) {
        self.accounts = accounts
        self.deleteError = deleteError
    }

    func list() async throws -> [BankAccount] {
        accounts
    }

    func add(_ draft: BankAccountDraft) async throws -> BankAccount {
        addedDrafts.append(draft)
        return BankAccount(
            id: "bank-\(addedDrafts.count)",
            bankName: draft.bankName,
            holderName: draft.holderName,
            accountNumberLast4: String(draft.accountNumber.suffix(4)),
            isDefault: false
        )
    }

    func setDefault(id: String) async throws -> BankAccount {
        guard let account = accounts.first(where: { $0.id == id }) else {
            throw NetworkError.notFound
        }
        return account
    }

    func delete(id: String) async throws {
        if let deleteError {
            throw deleteError
        }
        accounts.removeAll { $0.id == id }
    }
}
