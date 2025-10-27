//
//  SettingsModels.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 02.10.25.
//

import Foundation

struct Profile: Codable, Equatable {
    var name: String
    var email: String
    var avatarURL: URL?
    
    static let mock = Profile(
        name: "Иван Иванов",
        email: "ivan@example.com",
        avatarURL: URL(string: "https://i.pravatar.cc/150?img=5")
    )
}

enum AppTheme: String, CaseIterable, Codable {
    case system, light, dark
    
    var title: String {
        switch self {
        case .system: return "Системная"
        case .light:  return "Светлая"
        case .dark:   return "Тёмная"
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case system, ru, en
    
    var title: String {
        switch self {
        case .system: return "Системный"
        case .ru:     return "Русский"
        case .en:     return "English"
        }
    }
}

final class SettingsStore {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let profile = "settings.profile"
        static let theme = "settings.theme"
        static let notifications = "settings.notifications"
        static let language = "settings.language"
    }
    
    func loadProfile() -> Profile? {
        guard let data = defaults.data(forKey: Keys.profile) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: data)
    }
    
    func saveProfile(_ profile: Profile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: Keys.profile)
        }
    }
    
    func loadTheme() -> AppTheme {
        if let raw = defaults.string(forKey: Keys.theme),
           let theme = AppTheme(rawValue: raw) {
            return theme
        }
        return .system
    }
    
    func saveTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Keys.theme)
    }
    
    func loadNotificationsEnabled() -> Bool {
        defaults.object(forKey: Keys.notifications) as? Bool ?? true
    }
    
    func saveNotificationsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.notifications)
    }
    
    func loadLanguage() -> AppLanguage {
        if let raw = defaults.string(forKey: Keys.language),
           let lang = AppLanguage(rawValue: raw) {
            return lang
        }
        return .system
    }
    
    func saveLanguage(_ lang: AppLanguage) {
        defaults.set(lang.rawValue, forKey: Keys.language)
    }
}

