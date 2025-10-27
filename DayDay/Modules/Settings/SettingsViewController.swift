//
//  SettingsViewController.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit
import MessageUI
import SafariServices

final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel
    private let store = SettingsStore()
    
    // State
    private var profile: Profile = .mock
    private var theme: AppTheme = .system
    private var notificationsEnabled: Bool = true
    private var language: AppLanguage = .system
    
    // UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Sections/Rows
    private enum Section: Int, CaseIterable {
        case profile
        case general
        case about
    }
    
    private enum GeneralRow: Int, CaseIterable {
        case theme
        case notifications
        case language
    }
    
    private enum AboutRow: Int, CaseIterable {
        case version
        case policy
        case rate
        case feedback
    }
    
    // MARK: - Init
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.title
        
        loadState()
        setupTable()
        setupNavBar()
        applyTheme(theme)
    }
    
    // MARK: - Setup
    private func setupTable() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.reuseID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        tableView.register(SwitchCell.self, forCellReuseIdentifier: SwitchCell.reuseID)
        tableView.register(Value1Cell.self, forCellReuseIdentifier: Value1Cell.reuseID)
    }
    
    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Сохранить",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    // MARK: - State
    private func loadState() {
        profile = store.loadProfile() ?? .mock
        theme = store.loadTheme()
        notificationsEnabled = store.loadNotificationsEnabled()
        language = store.loadLanguage()
    }
    
    @objc private func saveTapped() {
        store.saveProfile(profile)
        store.saveTheme(theme)
        store.saveNotificationsEnabled(notificationsEnabled)
        store.saveLanguage(language)
        applyTheme(theme)
        
        let alert = UIAlertController(title: "Готово", message: "Настройки сохранены", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
    
    private func applyTheme(_ theme: AppTheme) {
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
    
    // MARK: - External actions
    private func openPolicy() {
        guard let url = URL(string: "https://example.com/privacy") else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    private func rateApp() {
        guard let url = URL(string: "https://apps.apple.com/app/id000000000?action=write-review") else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    private func sendFeedback() {
        let subject = "DayDay Feedback"
        let to = "support@example.com"
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.setSubject(subject)
            mail.setToRecipients([to])
            mail.mailComposeDelegate = self
            present(mail, animated: true)
        } else {
            let mailto = "mailto:\(to)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: mailto) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        guard let section = Section(rawValue: sectionIndex) else { return 0 }
        switch section {
        case .profile:
            return 2 // Profile summary cell + "Редактировать профиль"
        case .general:
            return GeneralRow.allCases.count
        case .about:
            return AboutRow.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        guard let section = Section(rawValue: sectionIndex) else { return nil }
        switch section {
        case .profile: return "Профиль"
        case .general: return "Общие"
        case .about:   return "О приложении"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .profile:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.reuseID, for: indexPath) as! ProfileCell
                cell.configure(name: profile.name, email: profile.email, avatarURL: profile.avatarURL)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
                cell.textLabel?.text = "Редактировать профиль"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .general:
            guard let row = GeneralRow(rawValue: indexPath.row) else { return UITableViewCell() }
            switch row {
            case .theme:
                let cell = tableView.dequeueReusableCell(withIdentifier: Value1Cell.reuseID, for: indexPath) as! Value1Cell
                cell.textLabel?.text = "Тема"
                cell.detailTextLabel?.text = theme.title
                cell.accessoryType = .disclosureIndicator
                return cell
            case .notifications:
                let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.reuseID, for: indexPath) as! SwitchCell
                cell.textLabel?.text = "Уведомления"
                cell.setOn(notificationsEnabled)
                cell.onToggle = { [weak self] isOn in
                    self?.notificationsEnabled = isOn
                }
                return cell
            case .language:
                let cell = tableView.dequeueReusableCell(withIdentifier: Value1Cell.reuseID, for: indexPath) as! Value1Cell
                cell.textLabel?.text = "Язык"
                cell.detailTextLabel?.text = language.title
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .about:
            guard let row = AboutRow(rawValue: indexPath.row) else { return UITableViewCell() }
            switch row {
            case .version:
                let cell = tableView.dequeueReusableCell(withIdentifier: Value1Cell.reuseID, for: indexPath) as! Value1Cell
                cell.textLabel?.text = "Версия"
                cell.detailTextLabel?.text = appVersionString()
                cell.selectionStyle = .none
                return cell
            case .policy:
                let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
                cell.textLabel?.text = "Политика конфиденциальности"
                cell.accessoryType = .disclosureIndicator
                return cell
            case .rate:
                let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
                cell.textLabel?.text = "Оставить отзыв"
                cell.accessoryType = .disclosureIndicator
                return cell
            case .feedback:
                let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
                cell.textLabel?.text = "Написать разработчику"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .profile:
            if indexPath.row == 1 {
                let vc = EditProfileViewController(profile: profile) { [weak self] newProfile in
                    self?.profile = newProfile
                    self?.tableView.reloadSections(IndexSet(integer: Section.profile.rawValue), with: .automatic)
                }
                navigationController?.pushViewController(vc, animated: true)
            }
        case .general:
            guard let row = GeneralRow(rawValue: indexPath.row) else { return }
            switch row {
            case .theme:
                showThemePicker()
            case .language:
                showLanguagePicker()
            case .notifications:
                break
            }
        case .about:
            guard let row = AboutRow(rawValue: indexPath.row) else { return }
            switch row {
            case .version:
                break
            case .policy:
                openPolicy()
            case .rate:
                rateApp()
            case .feedback:
                sendFeedback()
            }
        }
    }
}

// MARK: - Pickers
private extension SettingsViewController {
    func showThemePicker() {
        let alert = UIAlertController(title: "Тема", message: nil, preferredStyle: .actionSheet)
        AppTheme.allCases.forEach { t in
            alert.addAction(UIAlertAction(title: t.title, style: .default, handler: { [weak self] _ in
                self?.theme = t
                self?.tableView.reloadSections(IndexSet(integer: Section.general.rawValue), with: .none)
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    func showLanguagePicker() {
        let alert = UIAlertController(title: "Язык", message: nil, preferredStyle: .actionSheet)
        AppLanguage.allCases.forEach { lang in
            alert.addAction(UIAlertAction(title: lang.title, style: .default, handler: { [weak self] _ in
                self?.language = lang
                self?.tableView.reloadSections(IndexSet(integer: Section.general.rawValue), with: .none)
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    func appVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Cells

private final class ProfileCell: UITableViewCell {
    static let reuseID = "ProfileCell"
    
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let stack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        avatarView.layer.cornerRadius = 24
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.backgroundColor = .secondarySystemBackground
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        emailLabel.font = .systemFont(ofSize: 13)
        emailLabel.textColor = .secondaryLabel
        emailLabel.numberOfLines = 1
        
        stack.axis = .vertical
        stack.spacing = 4
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(emailLabel)
        
        let h = UIStackView(arrangedSubviews: [avatarView, stack])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        
        contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            h.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(name: String, email: String, avatarURL: URL?) {
        nameLabel.text = name
        emailLabel.text = email
        if let url = avatarURL {
            // Простая загрузка без кеша (можно заменить на SDWebImage при желании)
            avatarView.image = nil
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.avatarView.image = img
                }
            }.resume()
        } else {
            avatarView.image = UIImage(systemName: "person.fill")
            avatarView.tintColor = .tertiaryLabel
            avatarView.contentMode = .scaleAspectFit
        }
    }
}

private final class SwitchCell: UITableViewCell {
    static let reuseID = "SwitchCell"
    
    private let switchView = UISwitch()
    var onToggle: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        accessoryView = switchView
        selectionStyle = .none
        switchView.addTarget(self, action: #selector(changed), for: .valueChanged)
        textLabel?.font = .systemFont(ofSize: 17)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setOn(_ isOn: Bool) {
        switchView.isOn = isOn
    }
    
    @objc private func changed() {
        onToggle?(switchView.isOn)
    }
}

private final class Value1Cell: UITableViewCell {
    static let reuseID = "Value1Cell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        textLabel?.font = .systemFont(ofSize: 17)
        detailTextLabel?.textColor = .secondaryLabel
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Edit Profile

private final class EditProfileViewController: UIViewController {
    private var profile: Profile
    private let onDone: (Profile) -> Void
    
    // UI
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let avatarField = UITextField()
    private let stack = UIStackView()
    
    init(profile: Profile, onDone: @escaping (Profile) -> Void) {
        self.profile = profile
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Профиль"
        view.backgroundColor = .systemBackground
        
        stack.axis = .vertical
        stack.spacing = 12
        
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "Имя"
        nameField.text = profile.name
        
        emailField.borderStyle = .roundedRect
        emailField.placeholder = "Email"
        emailField.keyboardType = .emailAddress
        emailField.text = profile.email
        
        avatarField.borderStyle = .roundedRect
        avatarField.placeholder = "Avatar URL"
        avatarField.autocapitalizationType = .none
        avatarField.autocorrectionType = .no
        avatarField.text = profile.avatarURL?.absoluteString
        
        [nameField, emailField, avatarField].forEach(stack.addArrangedSubview)
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneTapped))
    }
    
    @objc private func doneTapped() {
        profile.name = nameField.text ?? ""
        profile.email = emailField.text ?? ""
        if let s = avatarField.text, !s.isEmpty {
            profile.avatarURL = URL(string: s)
        } else {
            profile.avatarURL = nil
        }
        onDone(profile)
        navigationController?.popViewController(animated: true)
    }
}
