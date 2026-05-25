import SwiftUI
import KilatUI

struct ScheduledJobsView: View {
    @Bindable var viewModel: ScheduledJobsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                if viewModel.bookings.isEmpty, viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Tokens.Space.xl)
                } else if viewModel.bookings.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.sections) { section in
                        sectionView(section)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.destructive)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Scheduled Jobs")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.bookings.isEmpty {
                await viewModel.load()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Tokens.Space.sm) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
            Text("No scheduled jobs")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func sectionView(_ section: ScheduledJobsSection) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text(section.bucket.title)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .textCase(.uppercase)
            ForEach(section.bookings) { booking in
                scheduledCard(booking)
            }
        }
    }

    private func scheduledCard(_ booking: Booking) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.md) {
            VStack(spacing: Tokens.Space.xxs) {
                Text(Self.timeFormatter.string(from: viewModel.scheduledDate(for: booking)))
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.primary)
                Circle()
                    .fill(Tokens.Color.primary)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Tokens.Color.separator)
                    .frame(width: 2, height: 64)
            }
            .frame(width: 62)

            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        Text(booking.petSpec.name.isEmpty ? booking.petSpec.petType.capitalized : booking.petSpec.name)
                            .font(Tokens.FontRole.titleM)
                            .foregroundStyle(Tokens.Color.textPrimary)
                        Text("\(booking.pickupAddress.city) → \(booking.dropoffAddress.city)")
                            .font(Tokens.FontRole.label)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Text(booking.status == .accepted ? "Confirmed" : "Reminder")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.online)
                        .padding(.horizontal, Tokens.Space.xs)
                        .padding(.vertical, 3)
                        .background(Tokens.Color.surfaceMuted, in: Capsule())
                }

                Link(destination: calendarURL(for: booking)) {
                    Label("Add to calendar", systemImage: "calendar.badge.plus")
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.primary)
                }
            }
            .padding(Tokens.Space.md)
            .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
        }
    }

    private func calendarURL(for booking: Booking) -> URL {
        let title = "Kilat job \(booking.bookingNumber)"
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Kilat%20job"
        return URL(string: "calshow://?title=\(encoded)") ?? URL(string: "calshow://")!
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}
