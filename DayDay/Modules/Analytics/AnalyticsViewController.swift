//
//  AnalyticsViewController.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit
import SwiftUI
import Alamofire

// Reuse existing models from other files:
// - Category (id, name, description)
// - NoteWithMeta (id, category, title, content, createdAt, editedAt)
// We’ll fetch categories, then notes per category, then compute analytics.

final class AnalyticsViewController: UIViewController {
    private let viewModel: AnalyticsViewModel
    
    // Data state
    private var categories: [Category] = []
    private var notesByCategory: [String: [NoteWithMeta]] = [:]
    private var isLoading: Bool = false {
        didSet { updateHosting() }
    }
    private var errorMessage: String? {
        didSet { updateHosting() }
    }
    
    // Hosting
    private var hosting: UIHostingController<AnalyticsView>?
    
    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.title
        
        // Initial SwiftUI view
        let swiftUIView = AnalyticsView(
            isLoading: isLoading,
            error: errorMessage,
            categories: categories,
            notesByCategory: notesByCategory,
            onRetry: { [weak self] in self?.loadAll() }
        )
        let host = UIHostingController(rootView: swiftUIView)
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        hosting = host
        
        // Load data
        loadAll()
    }
    
    private func updateHosting() {
        hosting?.rootView = AnalyticsView(
            isLoading: isLoading,
            error: errorMessage,
            categories: categories,
            notesByCategory: notesByCategory,
            onRetry: { [weak self] in self?.loadAll() }
        )
    }
    
    private func loadAll() {
        isLoading = true
        errorMessage = nil
        fetchCategories { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let cats):
                self.categories = cats
                self.fetchNotesForAllCategories(categories: cats) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let map):
                        self.notesByCategory = map
                        self.isLoading = false
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func fetchCategories(completion: @escaping (Result<[Category], Error>) -> Void) {
        let url = "https://dayday.azurewebsites.net/api/categories"
        AF.request(url)
            .validate()
            .responseDecodable(of: Categories.self) { response in
                switch response.result {
                case .success(let payload):
                    completion(.success(payload.dailyCategories))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    private func fetchNotesForAllCategories(categories: [Category], completion: @escaping (Result<[String: [NoteWithMeta]], Error>) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let group = DispatchGroup()
        var results: [String: [NoteWithMeta]] = [:]
        var firstError: Error?
        
        for cat in categories {
            group.enter()
            let encoded = cat.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cat.name
            let url = "https://dayday.azurewebsites.net/api/notes/\(encoded)"
            
            AF.request(url)
                .validate()
                .responseDecodable(of: GetDailyNotesResponse.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let payload):
                        results[cat.name] = payload.dailyNotes
                    case .failure(let error):
                        // Capture the first error; continue others to complete group.
                        if firstError == nil { firstError = error }
                        results[cat.name] = []
                    }
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }
    }
}

