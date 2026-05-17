import SwiftUI
import KilatUI

/// Row card shown in the Available Jobs list.
struct JobRowCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: Tokens.Space.xs) {
                    Image(kilatAsset: "paw")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Tokens.Color.primary)
                    Text(booking.petSpec.name.isEmpty ? "Pet" : booking.petSpec.name)
                        .font(Tokens.FontRole.bodyBold)
                        .foregroundStyle(Tokens.Color.textPrimary)
                }
                Spacer()
                Text(fareLabel)
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.primary)
            }

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                routeLine(dotColor: Tokens.Color.online, text: booking.pickupAddress.singleLineLabel)
                routeLine(dotColor: Tokens.Color.destructive, text: booking.dropoffAddress.singleLineLabel)
            }

            if let distance = booking.distanceKm {
                Text(String(format: "%.1f km", distance))
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private func routeLine(dotColor: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
                .lineLimit(2)
        }
    }

    private var fareLabel: String {
        let cents = booking.finalPriceCents ?? booking.estimatedPriceCents
        let amount = Double(cents) / 100
        return "\(booking.currency) \(String(format: "%.2f", amount))"
    }
}
