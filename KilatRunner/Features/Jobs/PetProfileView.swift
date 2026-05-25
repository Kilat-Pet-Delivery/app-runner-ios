import SwiftUI
import KilatUI

struct PetProfileView: View {
    @Bindable private var viewModel: PetProfileViewModel

    init(viewModel: PetProfileViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                if let pet = viewModel.pet {
                    header(pet)
                    chipSection(title: "Temperament", values: pet.temperament)
                    if pet.hasAllergyAlert {
                        allergyCard(pet.allergies)
                    }
                    detailCard(title: "Care notes", text: pet.careNotes)
                    detailCard(title: "Feeding", text: pet.feedingInstructions)
                    vetCard(pet.emergencyVet)
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.body)
                        .foregroundStyle(Tokens.Color.destructive)
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(Tokens.Space.md)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Pet profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.pet == nil {
                await viewModel.load()
            }
        }
    }

    private func header(_ pet: PetProfile) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack(alignment: .top, spacing: Tokens.Space.md) {
                Avatar(name: pet.name, size: 56)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text(pet.name)
                        .font(Tokens.FontRole.titleL)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text([pet.breed, pet.petType.capitalized].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(Tokens.FontRole.body)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
                Spacer()
            }
            HStack(spacing: Tokens.Space.sm) {
                MetricTile(label: "Weight", value: String(format: "%.1f kg", pet.weightKg))
                MetricTile(label: "Age", value: pet.ageYears.map { "\($0)y" } ?? "-")
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private func chipSection(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text(title)
                .font(Tokens.FontRole.bodyBold)
                .foregroundStyle(Tokens.Color.textPrimary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Tokens.Space.xs)], alignment: .leading, spacing: Tokens.Space.xs) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textPrimary)
                        .padding(.horizontal, Tokens.Space.sm)
                        .padding(.vertical, Tokens.Space.xs)
                        .background(Tokens.Color.surfaceMuted, in: Capsule())
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func allergyCard(_ allergies: [String]) -> some View {
        detailCard(title: "Allergies", text: allergies.joined(separator: ", "), tint: Tokens.Color.destructive)
    }

    private func detailCard(title: String, text: String, tint: Color = Tokens.Color.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text(title)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .textCase(.uppercase)
            Text(text.isEmpty ? "No notes provided." : text)
                .font(Tokens.FontRole.body)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func vetCard(_ vet: EmergencyVetContact) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("Emergency vet")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .textCase(.uppercase)
                    Text(vet.name)
                        .font(Tokens.FontRole.bodyBold)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    if let address = vet.address, !address.isEmpty {
                        Text(address)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }
                }
                Spacer()
            }
            HStack(spacing: Tokens.Space.sm) {
                if let url = URL(string: "tel://\(vet.phone)") {
                    Link(destination: url) {
                        Label("Call", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    // Message-owner wiring lands with the incident/support flow.
                } label: {
                    Label("Message owner", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }
}
