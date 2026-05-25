import SwiftUI
import KilatUI

struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @Bindable private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel? = nil, session: AppSession) {
        self.viewModel = viewModel ?? SettingsViewModel(session: session)
    }

    var body: some View {
        Form {
            Section("Preferences") {
                Picker("Language", selection: Binding(
                    get: { viewModel.settings.language },
                    set: { language in Task { await viewModel.setLanguage(language) } }
                )) {
                    ForEach(RunnerLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }

                Picker("Theme", selection: Binding(
                    get: { viewModel.settings.theme },
                    set: { theme in Task { await viewModel.setTheme(theme) } }
                )) {
                    ForEach(RunnerTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }

                ForEach(NotificationCategory.allCases) { category in
                    Toggle(category.title, isOn: Binding(
                        get: { viewModel.settings.notificationPreferences[category] ?? true },
                        set: { _ in Task { await viewModel.toggle(category) } }
                    ))
                }
            }

            Section("Privacy & Safety") {
                Picker("Account visibility", selection: $viewModel.settings.accountVisibility) {
                    ForEach(AccountVisibility.allCases) { visibility in
                        Text(visibility.title).tag(visibility)
                    }
                }
                NavigationLink("Blocked users", value: AuthenticatedRoute.support)
            }

            Section("App") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                NavigationLink("Send feedback", value: AuthenticatedRoute.support)
            }

            Section("Account") {
                Button("Sign out", role: .destructive) {
                    session.logout()
                }
            }
        }
        .navigationTitle("Settings")
        .task { await viewModel.load() }
    }
}
