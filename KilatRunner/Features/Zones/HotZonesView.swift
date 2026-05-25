import MapKit
import SwiftUI
import KilatUI

struct HotZonesView: View {
    @Bindable private var viewModel: HotZonesViewModel
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 3.1390, longitude: 101.6869),
            span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        )
    )

    init(viewModel: HotZonesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map
            zoneSheet
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Hot zones")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.zones.isEmpty {
                await viewModel.load()
            }
        }
    }

    private var map: some View {
        Map(position: $position) {
            ForEach(viewModel.zones) { zone in
                Annotation(zone.name, coordinate: zone.centroidCoordinate) {
                    ZoneMarker(zone: zone)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .ignoresSafeArea(edges: .bottom)
    }

    private var zoneSheet: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Capsule()
                .fill(Tokens.Color.separator)
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)

            HStack {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("Demand nearby")
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text("Move toward higher multipliers when jobs are quiet.")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Tokens.Color.primary)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.destructive)
            } else if viewModel.sortedZones.isEmpty {
                Text("No active hot zones right now.")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.sortedZones) { zone in
                    zoneRow(zone)
                }
            }
        }
        .padding(Tokens.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
    }

    private func zoneRow(_ zone: HotZone) -> some View {
        HStack(spacing: Tokens.Space.sm) {
            RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous)
                .fill(Tokens.Color.primary.opacity(max(0.12, zone.fillOpacity)))
                .frame(width: 12, height: 42)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(zone.name)
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
                if let distanceKm = zone.distanceKm {
                    Text(String(format: "%.1f km away", distanceKm))
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }
            Spacer()
            Text(String(format: "%.1fx", zone.multiplier))
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.primary)
                .padding(.horizontal, Tokens.Space.sm)
                .padding(.vertical, Tokens.Space.xxs)
                .background(Tokens.Color.primaryTonal, in: Capsule())
        }
    }
}

private struct ZoneMarker: View {
    let zone: HotZone
    @State private var pulses = false

    var body: some View {
        ZStack {
            if zone.pulses {
                Circle()
                    .stroke(Tokens.Color.primary.opacity(0.28), lineWidth: 2)
                    .frame(width: pulses ? 72 : 36, height: pulses ? 72 : 36)
                    .opacity(pulses ? 0 : 1)
            }
            Circle()
                .fill(Tokens.Color.primary.opacity(max(0.18, zone.fillOpacity)))
                .frame(width: 44, height: 44)
            Text(String(format: "%.1fx", zone.multiplier))
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.primary)
        }
        .onAppear {
            guard zone.pulses else { return }
            withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) {
                pulses = true
            }
        }
    }
}
