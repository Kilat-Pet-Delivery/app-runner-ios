import SwiftUI

struct PermissionRationaleSheet: View {
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.fill.viewfinder")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.blue)

            VStack(spacing: 10) {
                Text("Location Access")
                    .font(.title2.bold())

                Text("Kilat uses your location while you are online so customers can follow active deliveries and dispatch can match nearby jobs.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                Button {
                    onContinue()
                } label: {
                    Label("Continue", systemImage: "location")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Not Now") {
                    onCancel()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}

#Preview {
    PermissionRationaleSheet(onContinue: {}, onCancel: {})
}
