import XCTest
@testable import KilatRunner

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func test_load_populatesProfileAndTier_fromTwoCalls() async {
        let repository = FakeIdentityRepository()
        repository.profile = .fixture
        repository.tier = TierSnapshot(tier: .gold, deliveries30D: 112, onTimeRate: 0.96, acceptanceRate: 0.91, ratingAverage: 4.92)
        let viewModel = ProfileViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state?.profile.fullName, "Test Runner")
        XCTAssertEqual(viewModel.state?.tier.tier, .gold)
        XCTAssertEqual(repository.fetchMeCallCount, 1)
        XCTAssertEqual(repository.fetchTierCallCount, 1)
    }

    func test_load_toleratesTier404_fallsBackToBronze() async {
        let repository = FakeIdentityRepository()
        repository.profile = .fixture
        repository.fetchTierError = NetworkError.notFound
        let viewModel = ProfileViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state?.tier.tier, .bronze)
        XCTAssertNil(viewModel.errorMessage)
    }
}

final class IdentityRepositoryTests: XCTestCase {
    func test_uploadPhoto_postsMultipartWithPhotoFieldName() async throws {
        MockURLProtocol.reset()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let client = APIClient(baseURL: URL(string: "https://example.test/api/v1")!, session: URLSession(configuration: configuration))
        let tokenStore = MemoryTokenStore(access: "access-token", refresh: "refresh-token")
        let repository = IdentityRepository(apiClient: client, tokenStore: tokenStore)

        MockURLProtocol.requestHandler = { request in
            let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/me/photo")
            XCTAssertTrue(body.contains("name=\"photo\""))
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"success":true,"data":{"photo_url":"https://cdn.test/me.jpg"}}"#.data(using: .utf8))
        }

        let url = try await repository.uploadPhoto(data: Data([1, 2, 3]), fileName: "me.jpg", mimeType: "image/jpeg")

        XCTAssertEqual(url, "https://cdn.test/me.jpg")
    }
}

private final class FakeIdentityRepository: IdentityRepositoryProtocol {
    var profile: RunnerProfile = .fixture
    var tier = TierSnapshot(tier: .bronze, deliveries30D: 0, onTimeRate: 0, acceptanceRate: 0, ratingAverage: 0)
    var fetchTierError: Error?
    private(set) var fetchMeCallCount = 0
    private(set) var fetchTierCallCount = 0

    func fetchMe() async throws -> RunnerProfile {
        fetchMeCallCount += 1
        return profile
    }

    func fetchTier() async throws -> TierSnapshot {
        fetchTierCallCount += 1
        if let fetchTierError {
            throw fetchTierError
        }
        return tier
    }

    func updateProfile(name: String, phone: String) async throws -> RunnerProfile {
        profile
    }

    func uploadPhoto(data: Data, fileName: String, mimeType: String) async throws -> String {
        "https://cdn.test/me.jpg"
    }
}

private extension RunnerProfile {
    static let fixture = RunnerProfile(
        id: "runner-1",
        fullName: "Test Runner",
        phone: "+60123456780",
        email: "runner.test@kilat.my",
        photoURL: nil,
        vehicleType: "motorcycle",
        vehiclePlate: "KLT1234",
        deliveries: 42,
        onTimeRate: 0.97,
        acceptanceRate: 0.88,
        ratingAverage: 4.92,
        identityVerified: true,
        licenseVerified: true
    )
}

private final class MemoryTokenStore: TokenStore {
    private var access: String?
    private var refresh: String?

    init(access: String?, refresh: String?) {
        self.access = access
        self.refresh = refresh
    }

    func accessToken() -> String? { access }
    func refreshToken() -> String? { refresh }
    func saveAccessToken(_ token: String) throws { access = token }
    func saveRefreshToken(_ token: String) throws { refresh = token }
    func clear() {
        access = nil
        refresh = nil
    }
}
