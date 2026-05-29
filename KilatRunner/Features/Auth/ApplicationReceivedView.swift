import SwiftUI
import KilatUI

struct ApplicationReceivedView: View {
    @Environment(\.dismiss) private var dismiss
    let applicationId: String

    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            Spacer()
            Image(kilatAsset: "clock")
                .resizable()
                .renderingMode(.template)
                .frame(width: 64, height: 64)
                .foregroundStyle(Tokens.Color.primary)
                .accessibilityIdentifier("applicationReceivedClockIcon")

            VStack(spacing: Tokens.Space.xs) {
                Text("Application received")
                    .font(Tokens.FontRole.titleL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(applicationId)
                    .font(Tokens.FontRole.mono)
                    .foregroundStyle(Tokens.Color.primary)
                    .accessibilityIdentifier("applicationIdLabel")
            }

            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                timelineRow(step: "1", title: "Verify details")
                timelineRow(step: "2", title: "Orientation video")
                timelineRow(step: "3", title: "Start earning")
            }
            .padding(Tokens.Space.md)
            .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))

            PrimaryButton(title: "Back to sign in", icon: "arrow.left") {
                dismiss()
            }
            Spacer()
        }
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
    }

    private func timelineRow(step: String, title: String) -> some View {
        HStack(spacing: Tokens.Space.sm) {
            Text(step)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.onPrimary)
                .frame(width: 26, height: 26)
                .background(Tokens.Color.primary, in: Circle())
            Text(title)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
            Spacer()
        }
    }
}
