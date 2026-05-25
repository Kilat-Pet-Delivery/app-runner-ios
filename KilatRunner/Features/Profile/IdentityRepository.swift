import Foundation

protocol IdentityRepositoryProtocol {
    func fetchMe() async throws -> RunnerProfile
    func fetchTier() async throws -> TierSnapshot
    func updateProfile(name: String, phone: String) async throws -> RunnerProfile
    func uploadPhoto(data: Data, fileName: String, mimeType: String) async throws -> String
}

final class IdentityRepository: IdentityRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func fetchMe() async throws -> RunnerProfile {
        let envelope: APIResponseEnvelope<RunnerProfile> = try await authInterceptor.perform(.me)
        return envelope.data
    }

    func fetchTier() async throws -> TierSnapshot {
        let envelope: APIResponseEnvelope<TierSnapshot> = try await authInterceptor.perform(.tier)
        return envelope.data
    }

    func updateProfile(name: String, phone: String) async throws -> RunnerProfile {
        let envelope: APIResponseEnvelope<RunnerProfile> = try await authInterceptor.perform(
            .updateMe,
            body: UpdateProfileRequest(fullName: name, phone: phone)
        )
        return envelope.data
    }

    func uploadPhoto(data: Data, fileName: String, mimeType: String) async throws -> String {
        let envelope: APIResponseEnvelope<PhotoUploadResponse> = try await authInterceptor.uploadMultipart(
            .mePhoto,
            fileField: "photo",
            fileName: fileName,
            fileMIMEType: mimeType,
            fileData: data
        )
        return envelope.data.photoURL
    }
}
