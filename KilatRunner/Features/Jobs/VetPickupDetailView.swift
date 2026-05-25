import SwiftUI
import KilatUI

struct VetPickupDetailView: View {
    @Bindable private var viewModel: VetPickupDetailViewModel

    init(viewModel: VetPickupDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.md) {
                    patientStrip
                    medicationCard
                    handlingCard
                    vetContactCard
                    routeAndPayoutCard
                    if let errorMessage = viewModel.jobDetailViewModel.errorMessage {
                        Text(errorMessage)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.destructive)
                            .padding(Tokens.Space.md)
                            .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
                    }
                }
                .padding(Tokens.Space.md)
            }
            footer
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Vet pickup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var patientStrip: some View {
        HStack(alignment: .top, spacing: Tokens.Space.md) {
            Avatar(name: viewModel.booking.petSpec.name, size: 54)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(viewModel.booking.petSpec.name)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(viewModel.condition)
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                Text(String(format: "%.1f kg", viewModel.booking.petSpec.weightKg))
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            Spacer()
            if viewModel.requiresColdChain {
                Label("Cold chain", systemImage: "snowflake")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.primary)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private var medicationCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text("Medications")
                .font(Tokens.FontRole.bodyBold)
                .foregroundStyle(Tokens.Color.textPrimary)
            if viewModel.medications.isEmpty {
                Text("No medication handoff required.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
            } else {
                ForEach(viewModel.medications) { medication in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                            Text(medication.name)
                                .font(Tokens.FontRole.label)
                                .foregroundStyle(Tokens.Color.textPrimary)
                            Text(medication.dosage)
                                .font(Tokens.FontRole.caption)
                                .foregroundStyle(Tokens.Color.textSecondary)
                        }
                        Spacer()
                        if medication.requiresColdChain {
                            Image(systemName: "snowflake")
                                .foregroundStyle(Tokens.Color.primary)
                        }
                    }
                    if medication.id != viewModel.medications.last?.id {
                        Divider().background(Tokens.Color.separator)
                    }
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var handlingCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Post-op handling")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .textCase(.uppercase)
            Text(viewModel.handlingInstructions.isEmpty ? "Handle gently and keep the pet calm during transit." : viewModel.handlingInstructions)
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var vetContactCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("Vet contact")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .textCase(.uppercase)
                Text(viewModel.vetName)
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(viewModel.booking.pickupAddress.singleLineLabel)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            if !viewModel.vetPhone.isEmpty,
               let url = URL(string: "tel://\(viewModel.vetPhone)") {
                Link(destination: url) {
                    Image(systemName: "phone.fill")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var routeAndPayoutCard: some View {
        VStack(spacing: Tokens.Space.sm) {
            row("Pickup", viewModel.booking.pickupAddress.singleLineLabel)
            row("Drop-off", viewModel.booking.dropoffAddress.singleLineLabel)
            Divider().background(Tokens.Color.separator)
            HStack {
                Text("Payout")
                    .font(Tokens.FontRole.bodyBold)
                Spacer()
                Text(fareLabel)
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.primary)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        PrimaryButton(
            title: viewModel.jobDetailViewModel.isAccepting ? "Accepting" : "Continue \(fareLabel)",
            isLoading: viewModel.jobDetailViewModel.isAccepting,
            isEnabled: !viewModel.jobDetailViewModel.isAccepting,
            action: { Task { await viewModel.jobDetailViewModel.accept() } }
        )
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface)
        .tokenShadow(Tokens.Shadow.raised)
    }

    private var fareLabel: String {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        return "\(viewModel.booking.currency) \(String(format: "%.2f", Double(cents) / 100))"
    }
}
