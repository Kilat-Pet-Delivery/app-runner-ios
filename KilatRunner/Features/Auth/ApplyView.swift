import SwiftUI
import KilatUI

struct ApplyView: View {
    @Bindable private var viewModel: ApplyViewModel

    init(viewModel: ApplyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                valueStrip
                personalSection
                vehicleSection
                experienceSection
                consentSection
                submitSection
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Apply to join")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            isPresented: Binding(
                get: { viewModel.submittedApplicationId != nil },
                set: { newValue in if !newValue { viewModel.submittedApplicationId = nil } }
            )
        ) {
            ApplicationReceivedView(applicationId: viewModel.submittedApplicationId ?? "")
        }
    }

    private var valueStrip: some View {
        HStack(spacing: Tokens.Space.sm) {
            valuePill("RM 15-25")
            valuePill("Flexible")
            valuePill("Insured")
        }
    }

    private func valuePill(_ title: String) -> some View {
        Text(title)
            .font(Tokens.FontRole.caption)
            .foregroundStyle(Tokens.Color.onPrimaryTonal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Tokens.Space.sm)
            .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private var personalSection: some View {
        formSection(title: "Personal info") {
            formField("Full name", text: $viewModel.name)
            formField("+60 phone", text: $viewModel.phone, keyboard: .phonePad)
            formField("IC number", text: $viewModel.icNumber, keyboard: .numberPad)
        }
    }

    private var vehicleSection: some View {
        formSection(title: "Vehicle") {
            Picker("Vehicle", selection: $viewModel.vehicleType) {
                ForEach(VehicleType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)

            formField("Plate number", text: $viewModel.plateNumber)
                .textInputAutocapitalization(.characters)
        }
    }

    private var experienceSection: some View {
        formSection(title: "Pet experience") {
            FlexibleChipGrid(items: PetExperienceOption.allCases) { option in
                let selected = viewModel.petExperience.contains(option)
                Button {
                    viewModel.toggleExperience(option)
                } label: {
                    Text(option.label)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(selected ? Tokens.Color.onPrimary : Tokens.Color.textPrimary)
                        .padding(.horizontal, Tokens.Space.md)
                        .padding(.vertical, Tokens.Space.xs)
                        .background(selected ? Tokens.Color.primary : Tokens.Color.surfaceMuted, in: Capsule())
                }
            }

            Toggle("Comfortable with live pets", isOn: $viewModel.comfortableWithLivePets)
                .font(Tokens.FontRole.label)
        }
    }

    private var consentSection: some View {
        Toggle(isOn: $viewModel.consentAcknowledged) {
            Text("I confirm the details are accurate and agree to the runner policy.")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .toggleStyle(.switch)
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private var submitSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            PrimaryButton(
                title: viewModel.isSubmitting ? "Submitting" : "Submit application",
                icon: "paperplane.fill",
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.isSubmitEnabled,
                action: { Task { await viewModel.submit() } }
            )
        }
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text(title)
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
            content()
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private func formField(
        _ title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .padding(Tokens.Space.md)
            .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
    }
}

private struct FlexibleChipGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Tokens.Space.xs)], spacing: Tokens.Space.xs) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}
