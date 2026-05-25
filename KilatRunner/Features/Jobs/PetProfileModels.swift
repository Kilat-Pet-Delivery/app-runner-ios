import Foundation

struct PetProfile: Decodable, Equatable {
    let id: String
    let name: String
    let petType: String
    let breed: String
    let ageYears: Int?
    let weightKg: Double
    let temperament: [String]
    let allergies: [String]
    let careNotes: String
    let feedingInstructions: String
    let emergencyVet: EmergencyVetContact

    var hasAllergyAlert: Bool { !allergies.isEmpty }
}

struct EmergencyVetContact: Decodable, Equatable {
    let name: String
    let phone: String
    let address: String?
}
