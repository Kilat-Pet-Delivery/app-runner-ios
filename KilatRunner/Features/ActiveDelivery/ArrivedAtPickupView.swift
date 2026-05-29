import SwiftUI
import KilatUI

struct ArrivedAtPickupView: View {
    let vendorName: String
    let orderID: String
    let isLoading: Bool
    let onConfirmPickup: () -> Void
    let onItemMissing: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
                    .fill(Tokens.Color.surfaceMuted)
                RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                    .stroke(Tokens.Color.primary, style: StrokeStyle(lineWidth: 3, dash: [18, 10]))
                    .frame(height: 124)
                    .padding(Tokens.Space.lg)
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Tokens.Color.primary)
            }
            .frame(height: 190)

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text(vendorName)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(orderID)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }

            PrimaryButton(
                title: "Items picked up",
                icon: "shippingbox.fill",
                isLoading: isLoading,
                action: onConfirmPickup
            )

            SecondaryButton(title: "Item missing", icon: "exclamationmark.triangle.fill", action: onItemMissing)
        }
    }
}
