//
//  NotesByCategoryViewController.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 02.10.25.
//

import UIKit
import SnapKit
import Alamofire

// Wrapper for GET /api/notes/{category}
struct GetDailyNotesResponse: Sendable {
    let dailyNotes: [NoteWithMeta]
}

// Provide nonisolated Decodable conformance to avoid main-actor isolated conformance.
nonisolated extension GetDailyNotesResponse: Decodable { }

final class NotesByCategoryViewController: UIViewController {
    private let category: String
    
    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.hidesWhenStopped = true
        v.color = .secondaryLabel
        return v
    }()
    
    private let emptyStack = UIStackView()
    private let emptyIcon = UIImageView(image: UIImage(systemName: "tray"))
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()
    
    // Data
    private var notes: [NoteWithMeta] = [] {
        didSet { tableView.reloadData(); updateEmptyState() }
    }
    
    init(category: String) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
        self.title = category
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTable()
        setupEmptyState()
        setupIndicator()
        fetchNotes()
    }
    
    private func setupTable() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(NoteCell.self, forCellReuseIdentifier: NoteCell.reuseID)
        tableView.tableFooterView = UIView()
    }
    
    private func setupIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupEmptyState() {
        emptyStack.axis = .vertical
        emptyStack.spacing = 8
        emptyStack.alignment = .center
        
        emptyIcon.tintColor = .tertiaryLabel
        emptyIcon.contentMode = .scaleAspectFit
        emptyIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        
        emptyTitle.text = "Нет заметок"
        emptyTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        emptyTitle.textColor = .secondaryLabel
        
        emptySubtitle.text = "Здесь будут заметки категории \(category)"
        emptySubtitle.font = .systemFont(ofSize: 14)
        emptySubtitle.textColor = .tertiaryLabel
        emptySubtitle.numberOfLines = 0
        emptySubtitle.textAlignment = .center
        
        [emptyIcon, emptyTitle, emptySubtitle].forEach(emptyStack.addArrangedSubview)
        
        view.addSubview(emptyStack)
        emptyStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(24)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(24)
        }
        
        emptyStack.isHidden = true
    }
    
    private func updateEmptyState() {
        let isEmpty = notes.isEmpty
        emptyStack.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    private func fetchNotes() {
        activityIndicator.startAnimating()
        
        // Encode category in URL path safely
        let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category
        let url = "https://dayday.azurewebsites.net/api/notes/\(encoded)"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        AF.request(url)
            .validate()
            .responseDecodable(of: GetDailyNotesResponse.self, decoder: decoder) { [weak self] response in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                switch response.result {
                case .success(let payload):
                    DispatchQueue.main.async {
                        self.notes = payload.dailyNotes
                    }
                case .failure(let error):
                    print("Failed to fetch notes for \(self.category): \(error)")
                    DispatchQueue.main.async {
                        self.notes = []
                        self.showError(message: error.localizedDescription)
                    }
                }
            }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NotesByCategoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = notes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NoteCell.reuseID, for: indexPath) as! NoteCell
        cell.configure(with: item)
        return cell
    }
}

private final class NoteCell: UITableViewCell {
    static let reuseID = "NoteCell"
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        stack.axis = .vertical
        stack.spacing = 4
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        
        contentView.addSubview(stack)
        [titleLabel, subtitleLabel].forEach(stack.addArrangedSubview)
        
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with note: NoteWithMeta) {
        titleLabel.text = note.title
        // Prefer content; fall back to category + date if content is empty
        if !note.content.isEmpty {
            subtitleLabel.text = note.content
        } else {
            subtitleLabel.text = note.category
        }
    }
}
