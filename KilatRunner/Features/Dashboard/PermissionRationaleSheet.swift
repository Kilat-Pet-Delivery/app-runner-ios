import SwiftUI
import KilatUI

struct PermissionRationaleSheet: View {
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            Image(systemName: "location.fill.viewfinder")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)

            VStack(spacing: Tokens.Space.xs) {
                Text("Location Access")
                    .font(Tokens.FontRole.titleL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Kilat uses your location while you are online so customers can follow active deliveries and dispatch can match nearby jobs.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Tokens.Space.sm) {
                PrimaryButton(title: "Continue", icon: "location", action: onContinue)

                Button("Not Now", action: onCancel)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .buttonStyle(.borderless)
            }
        }
        .padding(Tokens.Space.xl)
        .presentationDetents([.medium])
    }
}

#Preview {
    PermissionRationaleSheet(onContinue: {}, onCancel: {})
}
