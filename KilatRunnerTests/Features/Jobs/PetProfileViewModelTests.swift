import XCTest
@testable import KilatRunner

@MainActor
final class PetProfileViewModelTests: XCTestCase {
    func test_load_decodesAllergiesArray_andExposesHighlight() async {
        let repository = FakePetProfileRepository()
        repository.pet = PetProfile(
            id: "pet-1",
            name: "Milo",
            petType: "cat",
            breed: "Persian",
            ageYears: 4,
            weightKg: 4.5,
            temperament: ["Calm", "Shy"],
            allergies: ["Chicken", "Dust"],
            careNotes: "Keep carrier covered.",
            feedingInstructions: "No food before appointment.",
            emergencyVet: EmergencyVetContact(name: "Happy Vet", phone: "+60312345678", address: nil)
        )
        let viewModel = PetProfileViewModel(bookingID: "booking-1", repository: repository)

        await viewModel.load()

        XCTAssertEqual(repository.lastBookingID, "booking-1")
        XCTAssertEqual(viewModel.pet?.allergies, ["Chicken", "Dust"])
        XCTAssertEqual(viewModel.pet?.hasAllergyAlert, true)
    }
}

private final class FakePetProfileRepository: PetProfileRepositoryProtocol {
    var pet = PetProfile(
        id: "pet-1",
        name: "Milo",
        petType: "cat",
        breed: "Persian",
        ageYears: 4,
        weightKg: 4.5,
        temperament: [],
        allergies: [],
        careNotes: "",
        feedingInstructions: "",
        emergencyVet: EmergencyVetContact(name: "", phone: "", address: nil)
    )
    private(set) var lastBookingID: String?

    func fetchPet(bookingID: String) async throws -> PetProfile {
        lastBookingID = bookingID
        return pet
    }
}
