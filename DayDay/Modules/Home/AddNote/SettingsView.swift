//
//  SettingsView.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 02.10.25.
//

import SwiftUI
import Combine

enum SettingsExternalAction {
    case openPolicy(URL)
    case sendFeedback(subject: String, to: String)
    case rateApp(URL)
}

@MainActor
final class SettingsScreenViewModel: ObservableObject {
    @Published var profile: Profile
    @Published var theme: AppTheme
    @Published var notificationsEnabled: Bool
    @Published var language: AppLanguage
    
    private let store = SettingsStore()
    
    init() {
        // Load from store or use defaults
        self.profile = store.loadProfile() ?? .mock
        self.theme = store.loadTheme()
        self.notificationsEnabled = store.loadNotificationsEnabled()
        self.language = store.loadLanguage()
    }
    
    func save() {
        store.saveProfile(profile)
        store.saveTheme(theme)
        store.saveNotificationsEnabled(notificationsEnabled)
        store.saveLanguage(language)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    var external: (SettingsExternalAction) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Профиль")) {
                    HStack(spacing: 12) {
                        AsyncAvatar(url: viewModel.profile.avatarURL)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.profile.name).font(.headline)
                            Text(viewModel.profile.email).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink("Редактировать профиль") {
                        ProfileEditView(profile: $viewModel.profile)
                            .navigationTitle("Профиль")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                
                Section(header: Text("Общие")) {
                    Picker("Тема", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    Toggle("Уведомления", isOn: $viewModel.notificationsEnabled)
                    Picker("Язык", selection: $viewModel.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.title).tag(lang)
                        }
                    }
                }
                
                Section(header: Text("О приложении")) {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text(appVersionString()).foregroundStyle(.secondary)
                    }
                    Button("Политика конфиденциальности") {
                        if let url = URL(string: "https://example.com/privacy") {
                            external(.openPolicy(url))
                        }
                    }
                    Button("Оставить отзыв") {
                        if let url = URL(string: "https://apps.apple.com/app/id000000000?action=write-review") {
                            external(.rateApp(url))
                        }
                    }
                    Button("Написать разработчику") {
                        external(.sendFeedback(subject: "DayDay Feedback", to: "support@example.com"))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        viewModel.save()
                        apply(theme: viewModel.theme)
                    }
                }
            }
        }
        .onAppear {
            apply(theme: viewModel.theme)
        }
    }
    
    private func appVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
    
    private func apply(theme: AppTheme) {
        switch theme {
        case .system:
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = .unspecified }
        case .light:
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = .light }
        case .dark:
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = .dark }
        }
    }
}

private struct AsyncAvatar: View {
    let url: URL?
    var body: some View {
        ZStack {
            Circle().fill(Color(.secondarySystemBackground))
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().scaleEffect(0.8)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit().padding(8)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .resizable().scaledToFit().padding(8)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .clipped()
    }
}

private struct ProfileEditView: View {
    @Binding var profile: Profile
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var avatarURLString: String = ""
    
    var body: some View {
        Form {
            Section("Основное") {
                TextField("Имя", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                TextField("Avatar URL", text: $avatarURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .onAppear {
            name = profile.name
            email = profile.email
            avatarURLString = profile.avatarURL?.absoluteString ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Готово") {
                    profile.name = name
                    profile.email = email
                    profile.avatarURL = URL(string: avatarURLString)
                }
            }
        }
    }
}
