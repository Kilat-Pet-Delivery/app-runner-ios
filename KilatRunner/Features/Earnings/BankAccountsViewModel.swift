import Foundation
import Observation

struct BankAccount: Decodable, Equatable, Identifiable {
    let id: String
    let bankName: String
    let holderName: String
    let accountNumberLast4: String
    var isDefault: Bool

    var maskedNumber: String {
        "•••• \(accountNumberLast4)"
    }
}

struct BankAccountDraft: Encodable, Equatable {
    let bankName: String
    let accountNumber: String
    let holderName: String
}

protocol BankAccountsRepositoryProtocol {
    func list() async throws -> [BankAccount]
    func add(_ draft: BankAccountDraft) async throws -> BankAccount
    func setDefault(id: String) async throws -> BankAccount
    func delete(id: String) async throws
}

final class BankAccountsRepository: BankAccountsRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func list() async throws -> [BankAccount] {
        let envelope: APIResponseEnvelope<[BankAccount]> = try await authInterceptor.perform(.bankAccounts)
        return envelope.data
    }

    func add(_ draft: BankAccountDraft) async throws -> BankAccount {
        let envelope: APIResponseEnvelope<BankAccount> = try await authInterceptor.perform(.addBankAccount, body: draft)
        return envelope.data
    }

    func setDefault(id: String) async throws -> BankAccount {
        let envelope: APIResponseEnvelope<BankAccount> = try await authInterceptor.perform(.setDefaultBankAccount(id: id))
        return envelope.data
    }

    func delete(id: String) async throws {
        let _: EmptyResponse = try await authInterceptor.perform(.deleteBankAccount(id: id))
    }
}

@MainActor
@Observable
final class BankAccountsViewModel {
    private(set) var accounts: [BankAccount] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?

    var defaultAccount: BankAccount? {
        accounts.first(where: \.isDefault)
    }

    @ObservationIgnored private let repository: BankAccountsRepositoryProtocol

    init(repository: BankAccountsRepositoryProtocol = BankAccountsRepository()) {
        self.repository = repository
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            accounts = try await repository.list()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func add(_ draft: BankAccountDraft) async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            let shouldBecomeDefault = accounts.isEmpty
            var created = try await repository.add(draft)
            if shouldBecomeDefault {
                created.isDefault = true
            }
            if created.isDefault {
                accounts = accounts.map { account in
                    var copy = account
                    copy.isDefault = false
                    return copy
                }
            }
            accounts.append(created)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func setDefault(id: String) async {
        errorMessage = nil

        do {
            let updated = try await repository.setDefault(id: id)
            accounts = accounts.map { account in
                var copy = account
                copy.isDefault = account.id == updated.id
                return copy
            }
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func delete(id: String) async {
        errorMessage = nil

        do {
            try await repository.delete(id: id)
            accounts.removeAll { $0.id == id }
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
