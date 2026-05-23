import SwiftUI
import KilatUI

#if canImport(UIKit)
import UIKit
#endif

struct ProofOfDeliveryView: View {
    @Bindable var viewModel: ProofOfDeliveryViewModel
    let isLivePet: Bool

#if canImport(UIKit)
    @State private var selectedImage: UIImage?
    @State private var signatureController = SignaturePadController()
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text("Proof of delivery")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)

            Picker("Recipient", selection: $viewModel.recipient) {
                ForEach(ProofRecipient.allCases) { recipient in
                    Text(recipient.label).tag(recipient)
                }
            }
            .pickerStyle(.segmented)

            if isLivePet {
                welfareBanner
            }

#if canImport(UIKit)
            PhotoCaptureZone(selectedImage: $selectedImage)
                .onChange(of: selectedImage) { _, image in
                    viewModel.photoData = image?.jpegData(compressionQuality: 0.82)
                }

            if viewModel.recipient.requiresSignature {
                SignaturePad(controller: signatureController)
                    .frame(height: 200)
                    .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            }
#endif

            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .font(Tokens.FontRole.body)
                .padding(Tokens.Space.sm)
                .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            PrimaryButton(
                title: "Submit proof",
                icon: "checkmark.seal.fill",
                isLoading: viewModel.isSubmitting,
                action: submit
            )
        }
    }

    private var welfareBanner: some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Image(kilatAsset: "paw")
                .resizable()
                .renderingMode(.template)
                .frame(width: 16, height: 16)
            Text("Confirm the pet is calm, hydrated, and safely handed over.")
                .font(Tokens.FontRole.caption)
        }
        .foregroundStyle(Tokens.Color.onPrimaryTonal)
        .padding(Tokens.Space.sm)
        .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
    }

    private func submit() {
#if canImport(UIKit)
        viewModel.signatureData = signatureController.signatureImage()?.pngData()
#endif
        Task { await viewModel.submit() }
    }
}
