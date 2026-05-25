import SwiftUI
import KilatUI

struct PreTripChecklistView: View {
    let booking: Booking
    let onBackToDashboard: () -> Void
    @Bindable private var viewModel: PreTripChecklistViewModel
    @State private var startsRoute = false

    init(
        booking: Booking,
        viewModel: PreTripChecklistViewModel,
        onBackToDashboard: @escaping () -> Void = {}
    ) {
        self.booking = booking
        self.viewModel = viewModel
        self.onBackToDashboard = onBackToDashboard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Pre-trip checklist")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text("Confirm the essentials before moving \(booking.petSpec.name.isEmpty ? "this pet" : booking.petSpec.name).")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }

            VStack(spacing: Tokens.Space.sm) {
                ForEach(PreTripChecklistItem.allCases) { item in
                    checklistRow(item)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            Spacer()

            PrimaryButton(
                title: "I'm ready to start",
                icon: "checkmark.circle.fill",
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.isReady,
                action: {
                    Task {
                        await viewModel.submit()
                        if viewModel.didSubmit {
                            startsRoute = true
                        }
                    }
                }
            )
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $startsRoute) {
            ActiveDeliveryView(
                viewModel: ActiveDeliveryViewModel(booking: booking),
                onBackToDashboard: onBackToDashboard
            )
        }
    }

    private func checklistRow(_ item: PreTripChecklistItem) -> some View {
        let isChecked = viewModel.checkedItems.contains(item)
        return Button {
            viewModel.toggle(item)
        } label: {
            HStack(spacing: Tokens.Space.md) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Tokens.Color.online : Tokens.Color.textTertiary)
                Text(item.title)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
            }
            .padding(Tokens.Space.md)
            .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
