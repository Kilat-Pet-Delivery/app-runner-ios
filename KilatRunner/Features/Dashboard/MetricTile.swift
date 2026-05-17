import SwiftUI
import KilatUI

/// Compact statistic card used on the Dashboard.
///
/// Two variants: `.emphasis` for the hero earnings number and `.standard`
/// for the secondary deliveries / online-time row.
struct MetricTile: View {
    enum Variant { case emphasis, standard }

    let label: String
    let value: String
    var caption: String? = nil
    var icon: String? = nil
    var variant: Variant = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack(spacing: Tokens.Space.xs) {
                if let icon {
                    Image(kilatAsset: icon)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(labelColor)
                }
                Text(label)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(labelColor)
                    .textCase(.uppercase)
            }

            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let caption {
                Text(caption)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(captionColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.Space.md)
        .background(backgroundFill, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(.init(color: .black.opacity(variant == .emphasis ? 0.10 : 0.04),
                           radius: variant == .emphasis ? 16 : 8,
                           x: 0, y: 4))
    }

    private var valueFont: Font {
        variant == .emphasis ? Tokens.FontRole.displayXL : Tokens.FontRole.titleL
    }

    private var backgroundFill: Color {
        variant == .emphasis ? Tokens.Color.primaryTonal : Tokens.Color.surface
    }

    private var labelColor: Color {
        variant == .emphasis ? Tokens.Color.onPrimaryTonal : Tokens.Color.textSecondary
    }

    private var valueColor: Color {
        variant == .emphasis ? Tokens.Color.onPrimaryTonal : Tokens.Color.textPrimary
    }

    private var captionColor: Color {
        variant == .emphasis ? Tokens.Color.onPrimaryTonal.opacity(0.8) : Tokens.Color.textSecondary
    }
}

#Preview {
    VStack(spacing: Tokens.Space.md) {
        MetricTile(label: "This week", value: "RM 482.50", caption: "+12% vs last week", variant: .emphasis)
        HStack(spacing: Tokens.Space.md) {
            MetricTile(label: "Deliveries", value: "24")
            MetricTile(label: "Online time", value: "9h 12m")
        }
    }
    .padding()
    .background(Tokens.Color.background)
}
